using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MusiqWindows.Services;
using uniffi.musiq_uniffi;

namespace MusiqWindows.ViewModels;

public partial class LibraryViewModel : ObservableObject
{
    [ObservableProperty]
    private bool _isScanning;

    [ObservableProperty]
    private string _statusMessage = "No folder scanned yet.";

    public ObservableCollection<TrackItem> Tracks { get; } = new();

    public LibraryViewModel()
    {
        _ = RefreshAsync();
    }

    [RelayCommand]
    private async Task RefreshAsync()
    {
        var tracks = await LibraryService.Instance.ListTracksAsync();

        Tracks.Clear();
        foreach (var track in tracks)
        {
            Tracks.Add(TrackItem.From(track));
        }
    }

    public async Task ScanFolderAsync(string folderPath)
    {
        IsScanning = true;
        StatusMessage = $"Scanning {folderPath}…";

        try
        {
            var count = await LibraryService.Instance.ScanFolderAsync(folderPath);
            StatusMessage = $"Scanned {count} track(s) from {folderPath}.";
            await RefreshAsync();
        }
        catch (MusiqException ex)
        {
            StatusMessage = $"Scan failed: {ex.Message}";
        }
        finally
        {
            IsScanning = false;
        }
    }

    [RelayCommand]
    private async Task PlayTrackAsync(TrackItem track)
    {
        try
        {
            await LibraryService.Instance.PlayTrackAsync(track);
        }
        catch (MusiqException ex)
        {
            StatusMessage = $"Playback failed: {ex.Message}";
        }
    }
}
