using Microsoft.UI.Xaml.Controls;
using MusiqWindows.ViewModels;

namespace MusiqWindows.Pages;

public sealed partial class SettingsPage : Page
{
    public SettingsViewModel ViewModel { get; } = new();

    public SettingsPage()
    {
        InitializeComponent();
        SettingsContentFrame.Navigate(typeof(SettingsHomePage), ViewModel);
    }
}
