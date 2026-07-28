using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.UI.Xaml;
using MusiqWindows.Services;
using uniffi.musiq_uniffi;

namespace MusiqWindows.ViewModels;

public partial class SettingsViewModel : ObservableObject
{
    private const string ThemeSetting = "AppTheme";
    private const string SoundSetting = "UiSoundEnabled";
    private const string TrackCheckboxesSetting = "ShowTrackSelectionCheckboxes";

    public string DatabasePath { get; } = LibraryService.Instance.DatabasePath;

    public string AppDataFolder { get; } = Windows.Storage.ApplicationData.Current.LocalFolder.Path;

    public string AppVersion { get; } = GetAppVersion();

    public ObservableCollection<string> ScannedFolders { get; } = new();

    [ObservableProperty]
    private string _libraryStatusMessage = string.Empty;

    // "System" / "Light" / "Dark" — kept as the plain string LocalSettings
    // already stores, rather than ElementTheme, so this ViewModel doesn't
    // need a WinUI dependency beyond what ApplyTheme already requires.
    [ObservableProperty]
    private string _selectedTheme = LoadSavedThemeName();

    partial void OnSelectedThemeChanged(string value)
    {
        Windows.Storage.ApplicationData.Current.LocalSettings.Values[ThemeSetting] = value;
        ApplyTheme(ThemeNameToElementTheme(value));
    }

    [ObservableProperty]
    private bool _uiSoundEnabled = LoadSavedSoundEnabled();

    partial void OnUiSoundEnabledChanged(bool value)
    {
        Windows.Storage.ApplicationData.Current.LocalSettings.Values[SoundSetting] = value;
        ApplySoundEnabled(value);
    }

    [ObservableProperty]
    private bool _showTrackSelectionCheckboxes = LoadSavedShowTrackSelectionCheckboxes();

    partial void OnShowTrackSelectionCheckboxesChanged(bool value) =>
        Windows.Storage.ApplicationData.Current.LocalSettings.Values[TrackCheckboxesSetting] = value;

    public SettingsViewModel()
    {
        _ = RefreshScannedFoldersAsync();
    }

    public async Task RefreshScannedFoldersAsync()
    {
        var roots = await LibraryService.Instance.ListScanRootsAsync();
        ScannedFolders.Clear();
        foreach (var root in roots)
        {
            ScannedFolders.Add(root);
        }
    }

    public async Task AddFolderAsync(string folderPath)
    {
        try
        {
            var count = await LibraryService.Instance.ScanFolderAsync(folderPath);
            LibraryStatusMessage = $"Scanned {count} track(s) from {folderPath}.";
            await RefreshScannedFoldersAsync();
        }
        catch (MusiqException ex)
        {
            LibraryStatusMessage = $"Scan failed: {ex.Message}";
        }
    }

    [RelayCommand]
    private async Task RemoveFolderAsync(string folderPath)
    {
        try
        {
            var count = await LibraryService.Instance.RemoveScanRootAsync(folderPath);
            LibraryStatusMessage = $"Removed {folderPath} ({count} track(s) forgotten — the files themselves are untouched).";
            await RefreshScannedFoldersAsync();
        }
        catch (MusiqException ex)
        {
            LibraryStatusMessage = $"Remove failed: {ex.Message}";
        }
    }

    private static string LoadSavedThemeName() =>
        Windows.Storage.ApplicationData.Current.LocalSettings.Values[ThemeSetting] as string ?? "System";

    private static ElementTheme ThemeNameToElementTheme(string name) => name switch
    {
        "Light" => ElementTheme.Light,
        "Dark" => ElementTheme.Dark,
        _ => ElementTheme.Default,
    };

    /// Reads the persisted theme choice without needing a live window —
    /// used by <see cref="MainWindow"/> at construction time, before
    /// <see cref="App.MainAppWindow"/> is assigned.
    public static ElementTheme LoadSavedTheme() => ThemeNameToElementTheme(LoadSavedThemeName());

    /// Applies a theme to the whole app by setting it on the root element
    /// (Window.Content) — FrameworkElement.RequestedTheme is the documented
    /// way to change theme at runtime (unlike Application.RequestedTheme,
    /// which throws if set after launch) and inherits down to every
    /// descendant unless overridden.
    public static void ApplyTheme(ElementTheme theme)
    {
        if (App.MainAppWindow?.Content is FrameworkElement root)
        {
            root.RequestedTheme = theme;
        }
    }

    /// Reads the persisted sound choice without needing a live ViewModel —
    /// used by <see cref="MainWindow"/> at construction time to apply it
    /// eagerly, the same way <see cref="LoadSavedTheme"/> is.
    public static bool LoadSavedSoundEnabled() =>
        Windows.Storage.ApplicationData.Current.LocalSettings.Values[SoundSetting] as bool? ?? false;

    /// ElementSoundPlayer is the documented API for the standard control
    /// interaction sounds (click, invoke, etc.) — Auto plays them on Xbox
    /// only, so a plain On/Off toggle covers desktop meaningfully.
    public static void ApplySoundEnabled(bool enabled) =>
        ElementSoundPlayer.State = enabled ? ElementSoundPlayerState.On : ElementSoundPlayerState.Off;

    /// Reads the persisted choice without needing a live ViewModel — used by
    /// <c>LibraryPage</c> when it builds the Tracks table.
    public static bool LoadSavedShowTrackSelectionCheckboxes() =>
        Windows.Storage.ApplicationData.Current.LocalSettings.Values[TrackCheckboxesSetting] as bool? ?? false;

    /// Written by <c>LibraryPage</c>'s own CommandBar toggle (a second entry
    /// point for the same setting besides the Settings page's ToggleSwitch),
    /// so both stay backed by the same LocalSettings value.
    public static void SaveShowTrackSelectionCheckboxes(bool value) =>
        Windows.Storage.ApplicationData.Current.LocalSettings.Values[TrackCheckboxesSetting] = value;

    private static string GetAppVersion()
    {
        var version = Windows.ApplicationModel.Package.Current.Id.Version;
        return $"{version.Major}.{version.Minor}.{version.Build}.{version.Revision}";
    }

    // Only window size + theme are exported/imported — Plex/Navidrome
    // credentials live in Windows' Credential Locker (PasswordVault) and are
    // deliberately never included in a plaintext file.
    private sealed record ExportedSettings(int? WindowWidth, int? WindowHeight, string Theme);

    public async Task ExportSettingsAsync(Windows.Storage.StorageFile file)
    {
        var settings = Windows.Storage.ApplicationData.Current.LocalSettings.Values;
        var export = new ExportedSettings(
            settings[MainWindow.WindowWidthSetting] as int?,
            settings[MainWindow.WindowHeightSetting] as int?,
            SelectedTheme);
        var json = System.Text.Json.JsonSerializer.Serialize(export);
        await Windows.Storage.FileIO.WriteTextAsync(file, json);
    }

    public async Task ImportSettingsAsync(Windows.Storage.StorageFile file)
    {
        var json = await Windows.Storage.FileIO.ReadTextAsync(file);
        var import = System.Text.Json.JsonSerializer.Deserialize<ExportedSettings>(json);
        if (import is null)
        {
            return;
        }

        var settings = Windows.Storage.ApplicationData.Current.LocalSettings.Values;
        if (import.WindowWidth is int width && import.WindowHeight is int height)
        {
            settings[MainWindow.WindowWidthSetting] = width;
            settings[MainWindow.WindowHeightSetting] = height;
            if (App.MainAppWindow is not null)
            {
                App.MainAppWindow.AppWindow.Resize(new Windows.Graphics.SizeInt32(width, height));
            }
        }

        if (!string.IsNullOrEmpty(import.Theme))
        {
            SelectedTheme = import.Theme;
        }
    }
}
