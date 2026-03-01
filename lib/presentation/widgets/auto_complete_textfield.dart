import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/utils/extenstions.dart';
import 'package:pos/presentation/widgets/custom_loading.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';

enum FilterType { startWith, endWith, contains }

typedef AutocompleteListWidget<T extends Object> = Widget Function(T options);

class AutoCompleteTextField<T extends Object> extends StatelessWidget {
  final List<T> items;
  final String Function(T model) displayStringFunction;
  final List<String> Function(T model)? searchFunction;
  final String defaultText;
  final String? labelText;
  Widget? prefixIcon;
  Widget? suffixIcon;
  bool? showAsUpperLabel;
  final void Function(T model) onSelected;
  final void Function(String value)? onChanged;
  final FocusNode? focusNode;
  final OptionsViewOpenDirection? optionsViewOpenDirection;
  final bool? enabled;
  final bool? disableSearch;
  final FilterType? filterType;
  final TextEditingController? controller;
  // final void Function(FocusNode)? getNode;
  bool? isLoading = false;
  AutocompleteOptionsViewBuilder<T>? optionsViewBuilder;
  AutocompleteListWidget<T>? viewWidget;
  List<TextInputFormatter>? inputFormatters;
  List<String>? selectedItems = [];
  final String? Function(String? value)? validator;
  double? maxHeight;

  final void Function(String)? onSubmitted;
  AutoCompleteTextField({
    super.key,
    required this.items,
    required this.displayStringFunction,
    required this.onSelected,
    this.isLoading,
    this.onChanged,
    this.optionsViewBuilder,
    this.searchFunction,
    this.maxHeight,
    this.selectedItems,
    this.viewWidget,
    this.disableSearch,
    this.labelText,
    this.showAsUpperLabel,
    required this.defaultText,
    this.focusNode,
    this.inputFormatters,
    this.enabled,
    this.filterType,
    this.controller,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.optionsViewOpenDirection,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<T>(
        optionsViewOpenDirection: optionsViewOpenDirection ?? OptionsViewOpenDirection.down,
        focusNode: focusNode ?? FocusNode(),
        textEditingController: controller ?? TextEditingController(),
        optionsBuilder: (TextEditingValue textEditingValue) {
          // print(optionsList.length.toString()+"qqqqqqqq");
          if (textEditingValue.text == '') {
            return items;
          } else {
            List<T> matches = <T>[];
            matches.addAll(items);

            matches.retainWhere((option) {
              List<String> displayString = (null != searchFunction ? searchFunction!(option) : [displayStringFunction(option)]);
              // bool anyStartsWithFlutetr = stringList.Any(s => s.StartsWith("flutetr", StringComparison.OrdinalIgnoreCase));

              if (null != filterType && filterType == FilterType.startWith) {
                return displayString.any((element) => element.toLowerCase().startsWith(textEditingValue.text.toLowerCase()));
              } else if (null != filterType && filterType == FilterType.endWith) {
                return displayString.any((element) => element.toLowerCase().endsWith(textEditingValue.text.toLowerCase()));
              } else {
                return displayString.any((element) => element.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              }
            });
            return matches;
          }
        },
        onSelected: (T) {
          if (null != focusNode) {
            focusNode!.unfocus();
          }
          return onSelected(T);
        },
        fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
          // focusNode.addListener(() {
          //   if (null != getNode) {
          //     getNode!(focusNode);
          //   }
          // });

          return SizedBox(
            // height: 58,
            child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: textEditingController,
                builder: (context, value, child) {
                  return SizedBox(
                    width: constraints.biggest.width,
                    child: CustomTextField(
                      labelText: labelText,
                      controller: controller ?? textEditingController,
                      enabled: enabled ?? true,
                      // readOnly: Responsive.isMobile()?(disableSearch??false):false,
                      readOnly: (disableSearch ?? false),
                      onChanged: (disableSearch ?? false)
                          ? (value) {
                              (controller ?? textEditingController).clear();
                            }
                          : onChanged,
                      inputFormatters: inputFormatters,
                      validator: validator,

                      suffixIcon: InkWell(
                          onTap: () {
                            if (focusNode.hasFocus) {
                              focusNode.unfocus();
                            } else {
                              //to handle when already selected item..then select dropdown icon ..the show list..when onchange called clear selected element
                              focusNode.requestFocus();
                              if (!textEditingController.text.isNullOrEmpty()) {
                                textEditingController.clear();
                                if (null != onChanged) {
                                  onChanged!("");
                                }
                              }
                            }
                          },
                          child: suffixIcon ??
                              (textEditingController.text.isNullOrEmpty()
                                  ?
                                  // Transform.rotate(angle: items.isNotEmpty ? 3.14159:0,
                                  // child:
                                  Icon(Icons.keyboard_arrow_down_outlined)
                                  // )
                                  : Icon(
                                      textEditingController.text.isNullOrEmpty() ? Icons.keyboard_arrow_down : Icons.clear_outlined,
                                      color: AppColors.hintFontColor,
                                      size: 16,
                                    ))),
                      prefixIcon: prefixIcon, showAsUpperLabel: showAsUpperLabel,
                      // cursorColor: AppColors.lightFontColor,
                      // style: const TextStyle(
                      //   fontSize: 15,
                      //   color: Colors.black,
                      // ),
                      onTap: () {
                        if (!focusNode.hasFocus) {
                          textEditingController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: textEditingController.value.text.length,
                          );
                        }
                        if (disableSearch ?? false) {
                          focusNode.requestFocus();
                          textEditingController.clear();
                          if (null != onChanged) {
                            onChanged!("");
                          }
                        }
                      },
                      focusNode: focusNode,
                      onSubmitted: (String value) {
                        onFieldSubmitted();
                        if (null != onSubmitted) {
                          onSubmitted!(value);
                        }

                        // Handle submission
                      },
                    ),
                    // child: TextField(
                    //   enabled: enabled??true,
                    //   // readOnly: Responsive.isMobile()?(disableSearch??false):false,
                    //   readOnly: (disableSearch??false),
                    //   onChanged: (disableSearch??false)?(value){
                    //     (controller??textEditingController).clear();
                    //   }:onChanged,
                    //   inputFormatters:inputFormatters,
                    //   cursorColor: AppColors.lightFontColor,
                    //   style: const TextStyle(
                    //     fontSize: 15,
                    //     color: Colors.black,
                    //   ),
                    //   onTap: () {
                    //     if(null!= focusNode && !focusNode.hasFocus) {
                    //       textEditingController.selection = TextSelection(
                    //         baseOffset: 0,
                    //         extentOffset: textEditingController.value.text.length,
                    //       );
                    //     }
                    //   },
                    //   decoration: InputDecoration(
                    //     border: OutlineInputBorder(
                    //       borderSide: const BorderSide(color: Colors.black),
                    //       borderRadius: BorderRadius.circular(4),
                    //     ),
                    //     hintStyle: TextStyle(
                    //       color: isDarkMode(context)
                    //           ? AppColors.white
                    //           : AppColors.lightFontColor,
                    //       fontSize: 15,
                    //       fontWeight: FontWeight.w600,
                    //     ),
                    //     enabledBorder: OutlineInputBorder(
                    //       borderSide:
                    //       const BorderSide(color: AppColors.lightFontColor),
                    //       borderRadius: BorderRadius.circular(4),
                    //     ),
                    //     focusedBorder: OutlineInputBorder(
                    //       borderSide:
                    //       const BorderSide(color: AppColors.lightFontColor),
                    //       borderRadius: BorderRadius.circular(4),
                    //     ),
                    //     contentPadding: const EdgeInsets.symmetric(
                    //         horizontal: 10, vertical: 10),
                    //     hintText: !focusNode.hasFocus ? defaultText : "",
                    //     suffixIcon: suffixIcon ?? Icon(Icons.arrow_drop_down_outlined),
                    //     prefixIcon: prefixIcon ?? null,
                    //   ),
                    //   controller: controller??textEditingController,
                    //   focusNode: node??focusNode,
                    //   onSubmitted: (String value) {
                    //     onFieldSubmitted();
                    //     if(null!=onSubmitted) {
                    //       onSubmitted!(value);
                    //     }
                    //
                    //     // Handle submission
                    //   },
                    // ),
                  );
                }),
          );
        },
        displayStringForOption: (T option) => displayStringFunction(option),
        optionsViewBuilder: optionsViewBuilder ??
            (BuildContext context, void Function(T) onSelected, Iterable<T> options) {
              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (bool didPop, callBack) {
                  FocusScope.of(context).unfocus();
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    // Remove focus when tapping outside
                    FocusScope.of(context).unfocus();
                  },
                  child: Align(
                    alignment: null != optionsViewOpenDirection && optionsViewOpenDirection == OptionsViewOpenDirection.up ? Alignment.bottomLeft : Alignment.topLeft,
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
                              maxHeight: maxHeight ?? (MediaQuery.sizeOf(context).height / 3.5),
                              maxWidth: constraints.biggest.width,
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: (isLoading ?? false) ? 1 : options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final T option = options.elementAt(index);
                                if ((isLoading ?? false)) {
                                  return Container(alignment: Alignment.center, padding: const EdgeInsets.all(10), child: const CustomLoading());
                                }

                                return InkWell(
                                  onTap: () {
                                    onSelected(option);
                                  },
                                  child: Container(
                                    color: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4),
                                      child: Builder(
                                        builder: (BuildContext context) {
                                          // final bool highlight =
                                          //     AutocompleteHighlightedOption.of(context) ==
                                          //         index;
                                          final bool? highlight = selectedItems?.map((item) => item.toLowerCase()).contains(displayStringFunction(option).toLowerCase());
                                          if (highlight ?? false) {
                                            SchedulerBinding.instance.addPostFrameCallback(
                                              (Duration timeStamp) {
                                                Scrollable.ensureVisible(context, alignment: 0.5);
                                              },
                                            );
                                          }
                                          return Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              color: (highlight ?? false) ? Theme.of(context).focusColor : null,
                                            ),
                                            child: null != viewWidget
                                                ? viewWidget!(option)
                                                : Padding(
                                                    padding: const EdgeInsets.all(6.0),
                                                    child: Text(
                                                      displayStringFunction(option),
                                                    ),
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
