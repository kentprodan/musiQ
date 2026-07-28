using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using MusiqWindows.ViewModels;
using Windows.Storage.Pickers;
using WinRT.Interop;

namespace MusiqWindows.Pages;

public sealed partial class SettingsAppDataPage : Page
{
    public SettingsViewModel ViewModel { get; private set; } = null!;

    public SettingsAppDataPage()
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

    private async void ExportSettingsButton_Click(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
    {
        var picker = new FileSavePicker
        {
            SuggestedFileName = "musiq-settings",
        };
        picker.FileTypeChoices.Add("Settings file", new List<string> { ".json" });

        var hwnd = WindowNative.GetWindowHandle(App.MainAppWindow!);
        InitializeWithWindow.Initialize(picker, hwnd);

        var file = await picker.PickSaveFileAsync();
        if (file is null)
        {
            return;
        }

        await ViewModel.ExportSettingsAsync(file);
        SettingsIoStatusText.Text = $"Settings exported to {file.Path}.";
    }

    private async void ImportSettingsButton_Click(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
    {
        var picker = new FileOpenPicker();
        picker.FileTypeFilter.Add(".json");

        var hwnd = WindowNative.GetWindowHandle(App.MainAppWindow!);
        InitializeWithWindow.Initialize(picker, hwnd);

        var file = await picker.PickSingleFileAsync();
        if (file is null)
        {
            return;
        }

        await ViewModel.ImportSettingsAsync(file);
        SettingsIoStatusText.Text = $"Settings imported from {file.Path}.";
    }
}
