using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using MusiqWindows.ViewModels;
using Windows.Storage.Pickers;
using WinRT.Interop;

namespace MusiqWindows.Pages;

public sealed partial class SettingsLibrariesPage : Page
{
    public SettingsViewModel ViewModel { get; private set; } = null!;

    public SettingsLibrariesPage()
    {
        InitializeComponent();
    }

    protected override void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        (ViewModel, var label) = ((SettingsViewModel, string))e.Parameter;
        SectionLabelText.Text = label;
        Bindings.Update();
    }

    private void BackToSettingsHome_Click(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
    {
        ElementSoundPlayer.Play(ElementSoundKind.GoBack);
        Frame.GoBack();
    }

    private async void AddFolderButton_Click(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
    {
        var picker = new FolderPicker
        {
            SuggestedStartLocation = PickerLocationId.MusicLibrary,
        };
        picker.FileTypeFilter.Add("*");

        var hwnd = WindowNative.GetWindowHandle(App.MainAppWindow!);
        InitializeWithWindow.Initialize(picker, hwnd);

        var folder = await picker.PickSingleFolderAsync();
        if (folder is null)
        {
            return;
        }

        AddFolderButton.IsEnabled = false;
        try
        {
            await ViewModel.AddFolderAsync(folder.Path);
        }
        finally
        {
            AddFolderButton.IsEnabled = true;
        }
    }

    private async void RemoveFolderButton_Click(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
    {
        if (sender is Button { Tag: string folderPath })
        {
            await ViewModel.RemoveFolderCommand.ExecuteAsync(folderPath);
        }
    }
}
