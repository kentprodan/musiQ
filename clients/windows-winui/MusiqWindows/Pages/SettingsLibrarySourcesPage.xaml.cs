using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using MusiqWindows.ViewModels;

namespace MusiqWindows.Pages;

public sealed partial class SettingsLibrarySourcesPage : Page
{
    public SettingsLibrarySourcesPage()
    {
        InitializeComponent();
        SourcesSectionFrame.Navigate(typeof(SourcesPage));
    }

    protected override void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        (_, var label) = ((SettingsViewModel, string))e.Parameter;
        SectionLabelText.Text = label;
    }

    private void BackToSettingsHome_Click(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
    {
        ElementSoundPlayer.Play(ElementSoundKind.GoBack);
        Frame.GoBack();
    }
}
