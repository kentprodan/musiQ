using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using MusiqWindows.ViewModels;

namespace MusiqWindows.Pages;

public sealed partial class SettingsAppearancePage : Page
{
    public SettingsViewModel ViewModel { get; private set; } = null!;

    public SettingsAppearancePage()
    {
        InitializeComponent();
    }

    protected override void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        (ViewModel, var label) = ((SettingsViewModel, string))e.Parameter;
        SectionLabelText.Text = label;
        Bindings.Update();

        foreach (var item in ThemeComboBox.Items)
        {
            if (item is ComboBoxItem { Tag: string tag } comboBoxItem && tag == ViewModel.SelectedTheme)
            {
                ThemeComboBox.SelectedItem = comboBoxItem;
                break;
            }
        }
    }

    private void ThemeComboBox_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (ThemeComboBox.SelectedItem is ComboBoxItem { Tag: string tag })
        {
            ViewModel.SelectedTheme = tag;
        }
    }

    private void BackToSettingsHome_Click(object sender, RoutedEventArgs e)
    {
        ElementSoundPlayer.Play(ElementSoundKind.GoBack);
        Frame.GoBack();
    }
}
