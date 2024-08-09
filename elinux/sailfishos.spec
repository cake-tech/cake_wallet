Name:       cake_wallet
Version:    1.0.0+100
Release:    100
Summary:    Cake Wallet port for SailfishOS
License:    MIT
BuildRequires: ffmpeg-tools
Requires: maliit-framework-wayland-glib

%description
Cake Wallet port for SailfishOS.

%prep
#pragma we have no source, so nothing here

%build
rm -rf files %{_datadir} || true
mkdir files
cp -r %{_bundledir}/* files
cp %{_sourcedir}/elinux/cake_wallet.desktop cake_wallet.desktop
cp %{_sourcedir}/assets/images/macos_icons/cakewallet_macos_icons/cakewallet_macos_1024.png logo.png

%install
mkdir -p %{buildroot}%{_libdir}
mkdir -p %{buildroot}/opt/cake_wallet
cp -r files/* %{buildroot}/opt/cake_wallet
chmod +x %{buildroot}/opt/cake_wallet/cake_wallet

mkdir -p %{buildroot}%{_datadir}/icons/hicolor/108x108/apps
mkdir -p %{buildroot}%{_datadir}/icons/hicolor/128x128/apps
mkdir -p %{buildroot}%{_datadir}/icons/hicolor/172x172/apps
mkdir -p %{buildroot}%{_datadir}/icons/hicolor/86x86/apps
ffmpeg -i logo.png -vf scale=108:108 %{buildroot}%{_datadir}/icons/hicolor/108x108/apps/cake_wallet.png
ffmpeg -i logo.png -vf scale=128:128 %{buildroot}%{_datadir}/icons/hicolor/128x128/apps/cake_wallet.png
ffmpeg -i logo.png -vf scale=172:172 %{buildroot}%{_datadir}/icons/hicolor/172x172/apps/cake_wallet.png
ffmpeg -i logo.png -vf scale=86:86   %{buildroot}%{_datadir}/icons/hicolor/86x86/apps/cake_wallet.png
mkdir -p %{buildroot}%{_datadir}/applications
cp cake_wallet.desktop %{buildroot}%{_datadir}/applications/cake_wallet.desktop

%files
/opt/cake_wallet/
%{_datadir}/icons/hicolor/*/apps/cake_wallet.png
%{_datadir}/applications/cake_wallet.desktop

%changelog