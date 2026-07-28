using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MusiqWindows.ViewModels;
using Windows.Storage.Pickers;
using WinRT.Interop;

namespace MusiqWindows.Pages;

public sealed partial class LibraryPage : Page
{
    public LibraryViewModel ViewModel { get; } = new();

    public LibraryPage()
    {
        InitializeComponent();
        // Needed only so the ItemTemplate's per-row Play button can reach the
        // page-level ViewModel via `{Binding ElementName=..., Path=DataContext.…}`
        // — every other binding on this page uses x:Bind and ignores DataContext.
        LibraryPageRoot.DataContext = ViewModel;
    }

    private async void ScanFolderButton_Click(object sender, RoutedEventArgs e)
    {
        var picker = new FolderPicker
        {
            SuggestedStartLocation = PickerLocationId.MusicLibrary,
        };
        picker.FileTypeFilter.Add("*");

        // FolderPicker is a WinRT API that needs an owner HWND in a desktop
        // (non-UWP) app — there's no ambient window to infer it from.
        var hwnd = WindowNative.GetWindowHandle(App.MainAppWindow!);
        InitializeWithWindow.Initialize(picker, hwnd);

        var folder = await picker.PickSingleFolderAsync();
        if (folder is null)
        {
            return;
        }

        ScanFolderButton.IsEnabled = false;
        try
        {
            await ViewModel.ScanFolderAsync(folder.Path);
        }
        finally
        {
            ScanFolderButton.IsEnabled = true;
        }
    }

    private async void EditTrackButton_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not Button button || button.Tag is not TrackItem track)
        {
            return;
        }

        // Pre-fill from the raw (un-fallback'd) values — Title/Artist/Album
        // on TrackItem carry placeholders like "Unknown Artist" that must
        // never get written into the file as if they were real tags.
        EditTitleBox.Text = track.RawTitle ?? string.Empty;
        EditArtistBox.Text = track.RawArtist ?? string.Empty;
        EditAlbumBox.Text = track.RawAlbum ?? string.Empty;
        EditTrackDialog.XamlRoot = XamlRoot;

        var result = await EditTrackDialog.ShowAsync();
        if (result != ContentDialogResult.Primary)
        {
            return;
        }

        await ViewModel.SaveTagEditAsync(track.Id, EditTitleBox.Text, EditArtistBox.Text, EditAlbumBox.Text);
    }

    private async void EditSelectedButton_Click(object sender, RoutedEventArgs e)
    {
        var selectedIds = TracksListView.SelectedItems
            .OfType<TrackItem>()
            .Select(t => t.Id)
            .ToList();

        if (selectedIds.Count == 0)
        {
            ViewModel.StatusMessage = "Select one or more tracks first.";
            return;
        }

        BatchArtistBox.Text = string.Empty;
        BatchAlbumBox.Text = string.Empty;
        BatchEditDialog.XamlRoot = XamlRoot;

        var result = await BatchEditDialog.ShowAsync();
        if (result != ContentDialogResult.Primary)
        {
            return;
        }

        await ViewModel.SaveBatchTagEditAsync(selectedIds, BatchArtistBox.Text, BatchAlbumBox.Text);
    }
}
