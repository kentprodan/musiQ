using CommunityToolkit.Mvvm.ComponentModel;
using MusiqWindows.Services;

namespace MusiqWindows.ViewModels;

public partial class SettingsViewModel : ObservableObject
{
    public string DatabasePath { get; } = LibraryService.Instance.DatabasePath;

    public string AppVersion { get; } = GetAppVersion();

    private static string GetAppVersion()
    {
        var version = Windows.ApplicationModel.Package.Current.Id.Version;
        return $"{version.Major}.{version.Minor}.{version.Build}.{version.Revision}";
    }
}
