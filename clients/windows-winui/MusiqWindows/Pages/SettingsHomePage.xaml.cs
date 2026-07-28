using CommunityToolkit.WinUI.Controls;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using MusiqWindows.ViewModels;

namespace MusiqWindows.Pages;

public sealed partial class SettingsHomePage : Page
{
    public SettingsViewModel ViewModel { get; private set; } = null!;

    public SettingsHomePage()
    {
        InitializeComponent();
    }

    protected override void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        ViewModel = (SettingsViewModel)e.Parameter;
    }

    private void SectionCard_Click(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
    {
        if (sender is not SettingsCard { Tag: string tag })
        {
            return;
        }

        var (pageType, label) = tag switch
        {
            "appearance" => (typeof(SettingsAppearancePage), "Appearance & behavior"),
            "libraries" => (typeof(SettingsLibrariesPage), "Libraries"),
            "sources" => (typeof(SettingsLibrarySourcesPage), "Library sources"),
            "appdata" => (typeof(SettingsAppDataPage), "App data"),
            _ => throw new InvalidOperationException($"Unknown settings section tag: {tag}"),
        };

        Frame.Navigate(pageType, (ViewModel, label));
    }
}
