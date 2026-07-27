// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using Microsoft.UI.Xaml.Controls;
using MusiqWindows.ViewModels;

namespace MusiqWindows.Pages;

public sealed partial class SettingsPage : Page
{
    public SettingsViewModel ViewModel { get; } = new();

    public SettingsPage()
    {
        InitializeComponent();
    }
}
