import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/view_model/integrations/moonpay_virtual_account/moonpay_virtual_account_view_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum _VirtualAccountOption {
  usdToUsdc,
  gbpToUsdc,
  eurToEurc,
}

extension VirtualAccountOptionX on _VirtualAccountOption {
  String get sourceCurrencyCode {
    switch (this) {
      case _VirtualAccountOption.usdToUsdc:
        return 'usd';
      case _VirtualAccountOption.gbpToUsdc:
        return 'gbp';
      case _VirtualAccountOption.eurToEurc:
        return 'eur';
    }
  }

  String get destinationCurrencyCode {
    switch (this) {
      case _VirtualAccountOption.usdToUsdc:
      case _VirtualAccountOption.gbpToUsdc:
        return 'usdc_sol';
      case _VirtualAccountOption.eurToEurc:
        return 'eurc_sol';
    }
  }
}

class OnboardingMoonPayVirtualAccountPage extends BasePage {
  OnboardingMoonPayVirtualAccountPage(this.moonPayVirtualAccountViewModel);

  final MoonPayVirtualAccountViewModel moonPayVirtualAccountViewModel;

  @override
  bool get gradientBackground => true;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (context, scaffold) => GradientBackground(scaffold: scaffold);

  @override
  String get title => '';

  @override
  Widget body(BuildContext context) {
    return _MoonPayVirtualAccountBody(viewModel: moonPayVirtualAccountViewModel);
  }
}

class _MoonPayVirtualAccountBody extends StatefulWidget {
  const _MoonPayVirtualAccountBody({required this.viewModel});

  final MoonPayVirtualAccountViewModel viewModel;

  @override
  State<_MoonPayVirtualAccountBody> createState() => _MoonPayVirtualAccountBodyState();
}

class _MoonPayVirtualAccountBodyState extends State<_MoonPayVirtualAccountBody> {
  final _emailController = TextEditingController();
  String? _emailError;

  bool get _isEmailValid {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  _VirtualAccountOption _selected = _VirtualAccountOption.usdToUsdc;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'Create Virtual Account',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Create a virtual bank account to receive USD or\nEUR directly to your wallet. No fees on incoming\ntransfers.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                    color: Colors.white.withOpacity(0.65),
                  ),
            ),
            const SizedBox(height: 22),
            Text(
              'Select Currency',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
                  ),
            ),
            const SizedBox(height: 10),
            _CurrencyCard(
              selected: _selected,
              onChanged: (v) => setState(() => _selected = v),
            ),
            const SizedBox(height: 22),
            Text(
              'Email',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
                  ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onChanged: (_) {
                setState(() {
                  _emailError = _isEmailValid ? null : 'Enter a valid email';
                });
              },
              decoration: InputDecoration(
                hintText: 'email@example.com',
                errorText: _emailError,
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Account details will include',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
                  ),
            ),
            const SizedBox(height: 12),
            _InfoRow(text: 'Personal account number (in your name)'),
            const SizedBox(height: 10),
            _InfoRow(text: 'Receive domestic transfers'),
            const Spacer(),
            Padding(
              padding: EdgeInsets.only(bottom: bottomPadding > 0 ? 8 : 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isEmailValid
                          ? () async {
                              final url = widget.viewModel.createAccountUrl(
                                sourceCurrencyCode: _selected.sourceCurrencyCode,
                                destinationCurrencyCode: _selected.destinationCurrencyCode,
                                email: _emailController.text.trim(),
                              );
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Create Virtual Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final wallet = widget.viewModel.appStore.wallet;
                          if (wallet == null) {
                            throw Exception('Wallet is null');
                          }

                          final externalCustomerId =
                              widget.viewModel.buildExternalCustomerId(wallet);
                          final detailsResponse = await widget.viewModel.fetchVirtualAccountDetails(
                            externalCustomerId: externalCustomerId,
                          );

                          if (!mounted) return;

                          await Navigator.pushNamed(
                            context,
                            Routes.moonPayVirtualAccountOnboarding,
                            arguments: {
                              'externalCustomerId': externalCustomerId,
                              'detailsResponse': detailsResponse,
                            },
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Unable to load account details')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'I Already Have An Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

class _CurrencyCard extends StatelessWidget {
  const _CurrencyCard({
    required this.selected,
    required this.onChanged,
  });

  final _VirtualAccountOption selected;
  final ValueChanged<_VirtualAccountOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _CurrencyRow(
            symbol: r'$',
            title: 'USD → USDC',
            subtitle: 'USD Virtual Account',
            selected: selected == _VirtualAccountOption.usdToUsdc,
            onTap: () => onChanged(_VirtualAccountOption.usdToUsdc),
          ),
          _Divider(),
          _CurrencyRow(
            symbol: '£',
            title: 'GBP → USDC',
            subtitle: 'GBP Virtual Account',
            selected: selected == _VirtualAccountOption.gbpToUsdc,
            onTap: () => onChanged(_VirtualAccountOption.gbpToUsdc),
          ),
          _Divider(),
          _CurrencyRow(
            symbol: '€',
            title: 'EURO → EURC',
            subtitle: 'EUR Virtual Account',
            selected: selected == _VirtualAccountOption.eurToEurc,
            onTap: () => onChanged(_VirtualAccountOption.eurToEurc),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withOpacity(0.06),
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.symbol,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String symbol;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                symbol,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _SelectionMark(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Icon(
          Icons.check,
          size: 18,
          color: Colors.black,
        ),
      );
    }

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1.2,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check,
            size: 18,
            color: Colors.lightBlueAccent.withOpacity(0.9),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.35,
                  color: Colors.white.withOpacity(0.75),
                ),
          ),
        ),
      ],
    );
  }
}
