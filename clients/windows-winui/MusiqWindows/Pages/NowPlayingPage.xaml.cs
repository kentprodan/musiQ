using Microsoft.UI.Xaml.Controls;
using MusiqWindows.ViewModels;

namespace MusiqWindows.Pages;

public sealed partial class NowPlayingPage : Page
{
    public NowPlayingViewModel ViewModel { get; } = new();

    public NowPlayingPage()
    {
        InitializeComponent();
        Unloaded += (_, _) => ViewModel.Detach();
    }
}
