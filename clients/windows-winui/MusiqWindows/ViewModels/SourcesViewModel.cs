using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MusiqWindows.Services;

namespace MusiqWindows.ViewModels;

public partial class SourcesViewModel : ObservableObject
{
    public ObservableCollection<string> ScannedFolders { get; } = new();

    [ObservableProperty]
    private string _statusMessage = "No folders scanned yet — add one from the Library page.";

    public SourcesViewModel()
    {
        _ = RefreshCommand.ExecuteAsync(null);
    }

    [RelayCommand]
    private async Task RefreshAsync()
    {
        var roots = await LibraryService.Instance.ListScanRootsAsync();

        ScannedFolders.Clear();
        foreach (var root in roots)
        {
            ScannedFolders.Add(root);
        }

        StatusMessage = ScannedFolders.Count == 0
            ? "No folders scanned yet — add one from the Library page."
            : $"{ScannedFolders.Count} folder(s) scanned.";
    }
}
