using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using MusiqWindows.ViewModels;
using UniffiPlexLibrary = uniffi.musiq_uniffi.PlexLibrary;
using UniffiPlexTrack = uniffi.musiq_uniffi.PlexTrack;

namespace MusiqWindows.Pages;

internal sealed partial class SourcesPage : Page
{
    public SourcesViewModel ViewModel { get; } = new();

    public SourcesPage()
    {
        InitializeComponent();
    }

    protected override void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        // Refresh every time the page is shown, since a scan on the Library
        // page may have added a new source since our last visit.
        _ = ViewModel.RefreshCommand.ExecuteAsync(null);
    }

    private async void PlexConnectButton_Click(object sender, RoutedEventArgs e)
    {
        await ViewModel.ConnectToPlexAsync(PlexServerUrlBox.Text, PlexTokenBox.Password);
    }

    private async void PlexLibraryButton_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: UniffiPlexLibrary library })
        {
            await ViewModel.LoadPlexLibraryAsync(library);
        }
    }

    private async void PlexTrackPlayButton_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: UniffiPlexTrack track })
        {
            await ViewModel.PlayPlexTrackAsync(track);
        }
    }
}
