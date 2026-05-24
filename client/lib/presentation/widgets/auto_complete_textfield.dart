import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/utils/extensions.dart';
import 'package:pos/presentation/widgets/custom_loading.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';

enum FilterType { startWith, endWith, contains }

typedef AutocompleteListWidget<T extends Object> = Widget Function(T options);

class AutoCompleteTextField<T extends Object> extends StatefulWidget {
  const AutoCompleteTextField({
    super.key,
    required this.items,
    required this.displayStringFunction,
    required this.onSelected,
    required this.defaultText,
    this.searchFunction,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.showAsUpperLabel,
    this.onChanged,
    this.focusNode,
    this.optionsViewOpenDirection,
    this.enabled,
    this.disableSearch,
    this.filterType,
    this.controller,
    this.isLoading = false,
    this.optionsViewBuilder,
    this.viewWidget,
    this.inputFormatters,
    this.selectedItems,
    this.validator,
    this.maxHeight,
    this.onSubmitted,
  });

  final List<T> items;
  final String Function(T model) displayStringFunction;
  final List<String> Function(T model)? searchFunction;
  final String defaultText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool? showAsUpperLabel;
  final void Function(T model) onSelected;
  final void Function(String value)? onChanged;
  final FocusNode? focusNode;
  final OptionsViewOpenDirection? optionsViewOpenDirection;
  final bool? enabled;
  final bool? disableSearch;
  final FilterType? filterType;
  final TextEditingController? controller;
  final bool? isLoading;
  final AutocompleteOptionsViewBuilder<T>? optionsViewBuilder;
  final AutocompleteListWidget<T>? viewWidget;
  final List<TextInputFormatter>? inputFormatters;
  final List<String>? selectedItems;
  final String? Function(String? value)? validator;
  final double? maxHeight;
  final void Function(String)? onSubmitted;

  @override
  State<AutoCompleteTextField<T>> createState() => _AutoCompleteTextFieldState<T>();
}

class _AutoCompleteTextFieldState<T extends Object> extends State<AutoCompleteTextField<T>> {
  FocusNode? _ownedFocusNode;
  TextEditingController? _ownedController;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _ownedFocusNode!;
  TextEditingController get _effectiveController => widget.controller ?? _ownedController!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode();
    }
    if (widget.controller == null) {
      _ownedController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<T>(
        optionsViewOpenDirection: widget.optionsViewOpenDirection ?? OptionsViewOpenDirection.down,
        focusNode: _effectiveFocusNode,
        textEditingController: _effectiveController,
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text == '') {
            return widget.items;
          }
          final matches = <T>[...widget.items];
          matches.retainWhere((option) {
            final displayString = widget.searchFunction != null
                ? widget.searchFunction!(option)
                : [widget.displayStringFunction(option)];
            if (widget.filterType == FilterType.startWith) {
              return displayString.any((element) => element.toLowerCase().startsWith(textEditingValue.text.toLowerCase()));
            }
            if (widget.filterType == FilterType.endWith) {
              return displayString.any((element) => element.toLowerCase().endsWith(textEditingValue.text.toLowerCase()));
            }
            return displayString.any((element) => element.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          });
          return matches;
        },
        onSelected: (T selection) {
          widget.focusNode?.unfocus();
          _effectiveFocusNode.unfocus();
          widget.onSelected(selection);
        },
        fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
          return SizedBox(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: textEditingController,
              builder: (context, value, child) {
                return SizedBox(
                  width: constraints.biggest.width,
                  child: CustomTextField(
                    labelText: widget.labelText,
                    controller: _effectiveController,
                    enabled: widget.enabled ?? true,
                    readOnly: widget.disableSearch ?? false,
                    onChanged: (widget.disableSearch ?? false)
                        ? (value) {
                            _effectiveController.clear();
                          }
                        : widget.onChanged,
                    inputFormatters: widget.inputFormatters,
                    validator: widget.validator,
                    suffixIcon: InkWell(
                      onTap: () {
                        if (focusNode.hasFocus) {
                          focusNode.unfocus();
                        } else {
                          focusNode.requestFocus();
                          if (!textEditingController.text.isNullOrEmpty()) {
                            textEditingController.clear();
                            widget.onChanged?.call('');
                          }
                        }
                      },
                      child: widget.suffixIcon ??
                          (textEditingController.text.isNullOrEmpty()
                              ? const Icon(Icons.keyboard_arrow_down_outlined)
                              : Icon(
                                  textEditingController.text.isNullOrEmpty()
                                      ? Icons.keyboard_arrow_down
                                      : Icons.clear_outlined,
                                  color: AppColors.hintFontColor,
                                  size: 16,
                                )),
                    ),
                    prefixIcon: widget.prefixIcon,
                    showAsUpperLabel: widget.showAsUpperLabel,
                    onTap: () {
                      if (!focusNode.hasFocus) {
                        textEditingController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: textEditingController.value.text.length,
                        );
                      }
                      if (widget.disableSearch ?? false) {
                        focusNode.requestFocus();
                        textEditingController.clear();
                        widget.onChanged?.call('');
                      }
                    },
                    focusNode: focusNode,
                    onSubmitted: (String value) {
                      onFieldSubmitted();
                      widget.onSubmitted?.call(value);
                    },
                  ),
                );
              },
            ),
          );
        },
        displayStringForOption: widget.displayStringFunction,
        optionsViewBuilder: widget.optionsViewBuilder ??
            (BuildContext context, void Function(T) onSelected, Iterable<T> options) {
              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (bool didPop, callBack) {
                  FocusScope.of(context).unfocus();
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Align(
                    alignment: widget.optionsViewOpenDirection == OptionsViewOpenDirection.up
                        ? Alignment.bottomLeft
                        : Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Material(
                        shadowColor: const Color(0xffb8b8b826),
                        borderRadius: BorderRadius.circular(14),
                        elevation: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: widget.maxHeight ?? (MediaQuery.sizeOf(context).height / 3.5),
                              maxWidth: constraints.biggest.width,
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: (widget.isLoading ?? false) ? 1 : options.length,
                              itemBuilder: (BuildContext context, int index) {
                                if (widget.isLoading ?? false) {
                                  return Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(10),
                                    child: const CustomLoading(),
                                  );
                                }

                                final T option = options.elementAt(index);
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  child: Container(
                                    color: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4),
                                      child: Builder(
                                        builder: (BuildContext context) {
                                          final highlight = widget.selectedItems
                                              ?.map((item) => item.toLowerCase())
                                              .contains(widget.displayStringFunction(option).toLowerCase());
                                          if (highlight ?? false) {
                                            SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
                                              Scrollable.ensureVisible(context, alignment: 0.5);
                                            });
                                          }
                                          return Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              color: (highlight ?? false) ? Theme.of(context).focusColor : null,
                                            ),
                                            child: widget.viewWidget != null
                                                ? widget.viewWidget!(option)
                                                : Padding(
                                                    padding: const EdgeInsets.all(6.0),
                                                    child: Text(widget.displayStringFunction(option)),
                                                  ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
      ),
    );
  }
}
