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
}
