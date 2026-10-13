import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/spark_settings/spark_stable_balance_conversion_impact.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/base_text_form_field.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/src/widgets/picker.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/dashboard/home_settings_view_model.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";

class SparkSettingsPage extends BasePage {
  SparkSettingsPage(this._homeSettingsViewModel);

  final HomeSettingsViewModel _homeSettingsViewModel;

  @override
  String? get title => S.current.stable_balance;

  String get _tokenLabel => _homeSettingsViewModel.stableBalanceTokenLabel ?? "USD";

  Future<void> _confirmAndActivate(BuildContext context) async {
    final preview = _homeSettingsViewModel.previewActivation();
    await showPopUp<void>(
      context: context,
      builder: (context) => AlertWithTwoActions(
        alertTitle: S.of(context).stable_balance_confirm_title,
        alertContent: "",
        alertContentTextWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${S.of(context).stable_balance_confirm_content} "
              "${_homeSettingsViewModel.slippageLabel(_homeSettingsViewModel.selectedMaxSlippageBps)}",
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 14, decoration: TextDecoration.none),
            ),
            SparkStableBalanceConversionImpact(
              preview: preview,
              activating: true,
              tokenLabel: _tokenLabel,
              fallbackThresholdText: _homeSettingsViewModel.thresholdDisplayLabel == null
                  ? S.of(context).stable_balance_confirm_threshold_automatic
                  : S.of(context).stable_balance_confirm_threshold(
                        _homeSettingsViewModel.thresholdDisplayLabel!,
                      ),
            ),
            const SizedBox(height: 12),
            Text(
              S.of(context).stable_balance_slippage_explainer,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        leftButtonText: S.of(context).cancel,
        rightButtonText: S.of(context).confirm,
        actionLeftButton: () => Navigator.of(context).pop(),
        actionRightButton: () {
          Navigator.of(context).pop();
          _homeSettingsViewModel.setStableBalanceActive(
            true,
            maxSlippageBps: _homeSettingsViewModel.selectedMaxSlippageBps,
          );
        },
      ),
    );
  }

  Future<void> _confirmAndDeactivate(BuildContext context) async {
    final preview = _homeSettingsViewModel.previewDeactivation();
    await showPopUp<void>(
      context: context,
      builder: (context) => AlertWithTwoActions(
        alertTitle: S.of(context).stable_balance_deactivate_title,
        alertContent: "",
        alertContentTextWidget: SparkStableBalanceConversionImpact(
          preview: preview,
          activating: false,
          tokenLabel: _tokenLabel,
        ),
        leftButtonText: S.of(context).cancel,
        rightButtonText: S.of(context).confirm,
        actionLeftButton: () => Navigator.of(context).pop(),
        actionRightButton: () {
          Navigator.of(context).pop();
          _homeSettingsViewModel.setStableBalanceActive(false);
        },
      ),
    );
  }

  Future<void> _pickMaxSlippage(BuildContext context) async {
    await showPopUp<void>(
      context: context,
      builder: (context) => Picker<int>(
        items: HomeSettingsViewModelBase.maxSlippagePresetsBps,
        selectedAtIndex: HomeSettingsViewModelBase.maxSlippagePresetsBps
            .indexOf(_homeSettingsViewModel.selectedMaxSlippageBps),
        displayItem: _homeSettingsViewModel.slippageLabel,
        mainAxisAlignment: MainAxisAlignment.start,
        isSeparated: false,
        onItemSelected: _homeSettingsViewModel.applyNewMaxSlippage,
      ),
    );
  }

  Future<void> _editConvertAbove(BuildContext context) async {
    final controller = TextEditingController(
      text: _homeSettingsViewModel.thresholdFiatAmount ?? "",
    );
    await showPopUp<void>(
      context: context,
      builder: (context) => AlertWithTwoActions(
        alertTitle: S.of(context).stable_balance_convert_above,
        alertContent: "",
        alertContentTextWidget: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.of(context).stable_balance_convert_above_subtitle),
            const SizedBox(height: 12),
            BaseTextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              hintText: S.of(context).automatic,
              prefix: const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Text(r"$"),
              ),
            ),
          ],
        ),
        leftButtonText: S.of(context).cancel,
        rightButtonText: S.of(context).save,
        actionLeftButton: () => Navigator.of(context).pop(),
        actionRightButton: () {
          Navigator.of(context).pop();
          _homeSettingsViewModel.applyNewThresholdFromFiat(controller.text);
        },
      ),
    );
  }

  Widget _failureBanner(BuildContext context) {
    final failed = _homeSettingsViewModel.failedSetting;
    if (failed == null) {
      return const SizedBox.shrink();
    }

    final revertedTo = _homeSettingsViewModel.failedSettingRevertedToLabel ?? "";
    final subtitle = failed == StableBalanceSetting.maxSlippage
        ? S.of(context).stable_balance_failed_subtitle_slippage
        : S.of(context).stable_balance_failed_subtitle_threshold;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Row(
              spacing: 6,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.error,
                ),
                Flexible(
                  child: Text(
                    S.of(context).stable_balance_failed_headline(revertedTo),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _applyingLabel(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          const Icon(Icons.sync, size: 12, color: Colors.orange),
          Flexible(
            child: Text(
              S.of(context).stable_balance_applying_reconnecting,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      );

  Widget _trailingValue(BuildContext context, String value, {required bool dimmed}) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: dimmed
                ? Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(140)
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );

  @override
  Widget body(BuildContext context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Observer(
            builder: (_) {
              final vm = _homeSettingsViewModel;
              final applyingSlippage = vm.applyingSetting == StableBalanceSetting.maxSlippage;
              final applyingThreshold = vm.applyingSetting == StableBalanceSetting.thresholdSats;
              final tokenLabel = vm.stableBalanceTokenLabel ?? "USD";

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _failureBanner(context),
                  NewListSections(
                    sections: {
                      "": [
                        ListItemToggle(
                          keyValue: "spark settings stable balance",
                          label: S.of(context).stable_balance_toggle_label,
                          subtitle: S.of(context).stable_balance_toggle_subtitle(tokenLabel),
                          value: vm.stableBalanceActive,
                          isLoading: vm.isTogglingStableBalance,
                          onChanged: (val) {
                            if (vm.isTogglingStableBalance) {
                              return;
                            }

                            if (val) {
                              _confirmAndActivate(context);
                            } else {
                              _confirmAndDeactivate(context);
                            }
                          },
                        ),
                        ListItemRegularRow(
                          keyValue: "spark settings convert above",
                          label: S.of(context).stable_balance_convert_above,
                          subtitle: applyingThreshold
                              ? null
                              : S.of(context).stable_balance_convert_above_subtitle,
                          bottomWidget: applyingThreshold
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: _applyingLabel(context),
                                )
                              : null,
                          trailingWidget: _trailingValue(
                            context,
                            vm.thresholdDisplayLabel ?? S.of(context).automatic,
                            dimmed: applyingThreshold,
                          ),
                          showArrow: false,
                          onTap:
                              vm.isTogglingStableBalance ? null : () => _editConvertAbove(context),
                        ),
                        ListItemRegularRow(
                          keyValue: "spark settings max slippage",
                          label: S.of(context).stable_balance_max_conversion_slippage,
                          bottomWidget: applyingSlippage
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: _applyingLabel(context),
                                )
                              : null,
                          trailingWidget: _trailingValue(
                            context,
                            vm.slippageLabel(vm.selectedMaxSlippageBps),
                            dimmed: applyingSlippage,
                          ),
                          showArrow: false,
                          onTap:
                              vm.isTogglingStableBalance ? null : () => _pickMaxSlippage(context),
                        ),
                      ],
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    vm.failedSetting != null
                        ? S.of(context).stable_balance_footer_failure
                        : S.of(context).stable_balance_footer_idle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
}
