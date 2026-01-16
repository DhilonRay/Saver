import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:saver/components/constants/colors.dart';
import 'package:saver/components/constants/images.dart';
import 'package:saver/components/text_styles.dart';
import 'package:saver/components/widgets/loading.dart';
import 'package:saver/components/widgets/others.dart';
import 'package:saver/components/widgets/space.dart';

class TextFormInputField extends StatelessWidget {
  final String? label;
  final Widget? labelSuffixWidget;
  final String? hint;
  final String labelSide;
  final Widget? prefixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final bool required;
  final InputBorder? boxBorder;
  final String? Function(String? text)? validator;
  final void Function(String text)? onChanged;
  final void Function()? onTap;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool? obscureText, readOnly;
  final bool? filled;
  final Color? fillColor;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? type;
  final double? marginBottom;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final bool isRequired;
  final TextEditingController? controller;
  final double? height;
  final Widget? errorWidget;
  final String? errorText;

  const TextFormInputField({
    super.key,
    this.label,
    this.onTap,
    this.hint,
    this.labelSide = '',
    this.prefixIcon,
    this.prefix,
    this.required = false,
    this.validator,
    this.onChanged,
    this.obscureText,
    this.initialValue,
    this.type,
    this.boxBorder,
    this.keyboardType,
    this.maxLines,
    this.readOnly,
    this.filled,
    this.fillColor,
    this.suffix,
    this.minLines,
    this.marginBottom,
    this.maxLength,
    this.isRequired = false,
    this.textStyle,
    this.hintStyle,
    this.controller,
    this.labelSuffixWidget,
    this.height,
    this.errorWidget,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label != null
            ? Text(
                label!,
                textAlign: TextAlign.start,
                style: AppTextStyles.bodyLargeMedium.copyWith(),
              )
            : const SizedBox(),
        label != null ? const VerticalGap(8) : const SizedBox(),
        TextFormField(
          controller: controller,
          obscureText: obscureText ?? false,
          keyboardType: type,
          onTap: onTap,
          minLines: minLines,
          maxLines: maxLines,
          maxLength: maxLength,
          readOnly: readOnly ?? false,
          style: textStyle ?? AppTextStyles.bodySmall,
          decoration: InputDecoration(
            prefixIcon: prefixIcon,
            suffixIcon: suffix,
            error: errorWidget,
            errorText: errorText,
            prefix: prefix,
            border: boxBorder,
            enabledBorder: boxBorder,
            focusedBorder: boxBorder,
            errorBorder: boxBorder,
            focusedErrorBorder: boxBorder,
            hintText: hint,
            hintStyle: hintStyle ??
                AppTextStyles.bodySmall.copyWith(color: AppColors.tertiary),
            filled: filled ?? false,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            errorMaxLines: 2,
            errorStyle: AppTextStyles.bodySmall.copyWith(
              color: AppColors.error,
            ),
          ),
          onChanged: onChanged,
          validator: validator,
          initialValue: initialValue,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }
}

/*<-------Custom TextFormField configured with Theme.-------->*/
class TextFormFieldWidget extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextStyle? hintTextStyle;
  final Widget? labelPrefixIcon;
  final bool isPasswordTextField;
  final bool isReadOnly;
  final TextInputType? textInputType;
  final TextEditingController? controller;
  final int? minLines;
  final int? maxLines;
  final double suffixRightPaddingSize;
  final BoxConstraints prefixIconConstraints;
  final BoxConstraints suffixIconConstraints;
  final double prefixLeftPaddingSize;
  final void Function()? onTap;
  final String? Function(String? text)? validator;
  final bool isFilled;
  final bool isLabelWhiteText;
  final bool isRequired;
  final bool isOptional;
  final Color? fillColor;
  final InputBorder? border;
  final Widget? prefix;
  final Widget? suffix;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final void Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final double height;

  const TextFormFieldWidget({
    super.key,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.hintText,
    this.isPasswordTextField = false,
    this.isReadOnly = false,
    this.textInputType,
    this.controller,
    this.minLines,
    this.maxLines,
    this.onTap,
    this.labelPrefixIcon,
    this.suffixRightPaddingSize = 16,
    this.hintTextStyle,
    this.prefixLeftPaddingSize = 16,
    this.validator,
    this.suffixIconConstraints = const BoxConstraints(maxHeight: 40),
    this.isFilled = true,
    this.fillColor,
    this.border,
    this.isLabelWhiteText = false,
    this.isRequired = false,
    this.isOptional = false,
    this.prefixIconConstraints = const BoxConstraints(maxHeight: 40),
    this.prefix,
    this.suffix,
    this.onChanged,
    this.focusNode,
    this.onFieldSubmitted,
    this.textInputAction,
    this.height = 44,
  });

  Widget textFormFieldWidget() {
    return SizedBox(
      height: height,
      child: TextFormField(
        focusNode: focusNode,
        controller: controller,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        onTap: onTap,
        readOnly: isReadOnly,
        obscuringCharacter: '*',
        obscureText: isPasswordTextField,
        keyboardType: textInputType,
        textInputAction: textInputAction,
        textAlignVertical: TextAlignVertical.center,
        minLines: isPasswordTextField ? 1 : minLines,
        maxLines: isPasswordTextField ? 1 : maxLines,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: AppTextStyles.bodySmall,
        decoration: InputDecoration(
          hintText: hintText,
          hintMaxLines: 1,
          hintStyle: hintTextStyle ??
              AppTextStyles.bodySmall.copyWith(color: AppColors.tertiary),
          border: border,
          enabledBorder: border,
          filled: isFilled,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          prefixIconConstraints: prefixIconConstraints,
          suffixIconConstraints: suffixIconConstraints,
          prefix: prefix ??
              (prefixIcon != null ? prefix ?? const HorizontalGap(16) : null),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: prefixLeftPaddingSize),
            child: prefixIcon ?? const SizedBox.shrink(),
          ),
          suffix:
              suffix ?? (suffixIcon != null ? const HorizontalGap(14) : null),
          suffixIcon: Padding(
            padding: EdgeInsets.only(right: suffixRightPaddingSize),
            child: suffixIcon ?? const SizedBox.shrink(),
          ),
          errorMaxLines: 2,
          errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (labelText != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelPrefixIcon != null
                  ? Container(
                      alignment: Alignment.topLeft,
                      constraints: const BoxConstraints(minHeight: 10),
                      child: labelPrefixIcon,
                    )
                  : const SizedBox.shrink(),
              labelPrefixIcon != null
                  ? const HorizontalGap(15)
                  : const SizedBox.shrink(),
              Expanded(
                child: Row(
                  children: [
                    Text(labelText!, style: AppTextStyles.bodyLargeMedium),
                    if (isRequired)
                      Text(
                        ' *',
                        style: AppTextStyles.bodyLargeMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    if (isOptional) const HorizontalGap(5),
                    if (isOptional)
                      Text(
                        '(${'Optional'.tr})',
                        style: AppTextStyles.bodyLargeMedium.copyWith(
                          color: AppColors.tertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const VerticalGap(8),
          textFormFieldWidget(),
        ],
      );
    } else {
      return textFormFieldWidget();
    }
  }
}

class PhoneNumberTextFormFieldWidget extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextStyle? hintTextStyle;
  final Widget? labelPrefixIcon;
  final bool isPasswordTextField;
  final bool isReadOnly;
  final TextEditingController? controller;
  final int minLines;
  final int maxLines;
  final double suffixRightPaddingSize;
  final BoxConstraints prefixIconConstraints;
  final BoxConstraints suffixIconConstraints;
  final double prefixLeftPaddingSize;
  final void Function()? onTap;
  final String? Function(String?)? validator;
  final bool isFilled;
  final bool isLabelWhiteText;
  final bool isRequired;
  final Color? fillColor;
  final InputBorder? border;
  final Widget? prefix;
  final Widget? suffix;
  final void Function(String)? onChanged;
  final double height;

  const PhoneNumberTextFormFieldWidget({
    super.key,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.hintText,
    this.isPasswordTextField = false,
    this.isReadOnly = false,
    this.controller,
    this.minLines = 1,
    this.maxLines = 1,
    this.onTap,
    this.labelPrefixIcon,
    this.suffixRightPaddingSize = 16,
    this.hintTextStyle,
    this.prefixLeftPaddingSize = 16,
    this.validator,
    this.suffixIconConstraints = const BoxConstraints(maxHeight: 40),
    this.isFilled = true,
    this.fillColor,
    this.border,
    this.isLabelWhiteText = false,
    this.isRequired = false,
    this.prefixIconConstraints = const BoxConstraints(maxHeight: 40),
    this.prefix,
    this.suffix,
    this.onChanged,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormFieldWidget(
      height: height,
      onChanged: onChanged,
      labelText: labelText,
      hintText: hintText,
      prefix: const HorizontalGap(0),
      prefixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // SizedBox(
          //   width: 30,
          //   child: SvgPicture.asset(AppImages.bdFlagSvg),
          // ),
          // const HorizontalGap(8),
          Icon(Icons.phone, color: AppColors.secondary),
          const HorizontalGap(8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // const VerticalGap(1),
              Text(
                '+88',
                style: TextStyle(color: AppColors.primaryText, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
      suffix: suffix,
      suffixIcon: suffixIcon,
      hintTextStyle: hintTextStyle,
      labelPrefixIcon: labelPrefixIcon,
      isPasswordTextField: isPasswordTextField,
      isReadOnly: isReadOnly,
      textInputType: TextInputType.phone,
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      suffixRightPaddingSize: suffixRightPaddingSize,
      prefixIconConstraints: prefixIconConstraints,
      suffixIconConstraints: suffixIconConstraints,
      prefixLeftPaddingSize: prefixLeftPaddingSize,
      onTap: onTap,
      validator: validator,
      isFilled: isFilled,
      isLabelWhiteText: isLabelWhiteText,
      isRequired: isRequired,
      fillColor: fillColor,
      border: border,
    );
  }
}

class SearchTextFormFieldWidget extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextStyle? hintTextStyle;
  final Widget? labelPrefixIcon;
  final bool isPasswordTextField;
  final bool isReadOnly;
  final TextInputType? textInputType;
  final TextEditingController? controller;
  final int? minLines;
  final int? maxLines;
  final double suffixRightPaddingSize;
  final BoxConstraints prefixIconConstraints;
  final BoxConstraints suffixIconConstraints;
  final double prefixLeftPaddingSize;
  final void Function()? onTap;
  final String? Function(String?)? validator;
  final bool isFilled;
  final bool isLabelWhiteText;
  final bool isRequired;
  final Color? fillColor;
  final InputBorder? border;
  final Widget? prefix;
  final Widget? suffix;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;

  const SearchTextFormFieldWidget({
    super.key,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.hintText,
    this.isPasswordTextField = false,
    this.isReadOnly = false,
    this.controller,
    this.minLines,
    this.maxLines,
    this.onTap,
    this.labelPrefixIcon,
    this.suffixRightPaddingSize = 16,
    this.hintTextStyle,
    this.prefixLeftPaddingSize = 16,
    this.validator,
    this.suffixIconConstraints = const BoxConstraints(maxHeight: 40),
    this.isFilled = true,
    this.fillColor,
    this.border,
    this.isLabelWhiteText = false,
    this.isRequired = false,
    this.prefixIconConstraints = const BoxConstraints(maxHeight: 40),
    this.prefix,
    this.suffix,
    this.textInputType,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormFieldWidget(
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      textInputAction: textInputAction,
      labelText: labelText,
      hintText: hintText,
      prefix: const HorizontalGap(8),
      prefixIcon: SvgPicture.asset(AppImages.searchSvg),
      suffix: suffix,
      suffixIcon: suffixIcon,
      hintTextStyle: hintTextStyle,
      labelPrefixIcon: labelPrefixIcon,
      isPasswordTextField: isPasswordTextField,
      isReadOnly: isReadOnly,
      textInputType: textInputType,
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      suffixRightPaddingSize: suffixRightPaddingSize,
      prefixIconConstraints: prefixIconConstraints,
      suffixIconConstraints: suffixIconConstraints,
      prefixLeftPaddingSize: prefixLeftPaddingSize,
      onTap: onTap,
      validator: validator,
      isFilled: isFilled,
      isLabelWhiteText: isLabelWhiteText,
      isRequired: isRequired,
      fillColor: fillColor,
      border: border,
    );
  }
}

/* <-------- Searchable Drop down Button Form Field Widget -------> */
class SearchableDropdownButtonFormFieldWidget<T> extends StatefulWidget {
  final T? value;
  final String? hintText;
  final Widget? prefixIcon;
  final bool isLoading;
  final String? labelText;
  final List<T>? items;
  final String Function(T item)? getItemText;
  final BoxConstraints prefixIconConstraints;
  final Widget Function(T item)? getItemChild;
  final void Function(T? item)? onChanged;
  final String? Function(T? item)? validator;
  final TextEditingController? controller;
  final bool isDense;
  final bool isDisabled;
  final double? menuMaxHeight;
  final Widget? labelSuffixWidget;
  final String labelSide;
  final Widget? prefix;
  final Widget? suffix;
  final bool required;
  final InputBorder boxBorder;
  final void Function()? onTap;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool? obscureText, readOnly;
  final int? maxLines;
  final int? lines;
  final int? maxLength;
  final TextInputType? type;
  final double? marginBottom;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final bool isRequired;
  final double? height;
  final String? emptyMessage;

  const SearchableDropdownButtonFormFieldWidget({
    super.key,
    this.value,
    this.hintText,
    this.prefixIcon,
    this.items,
    this.getItemText,
    required this.onChanged,
    this.prefixIconConstraints = const BoxConstraints(
      maxHeight: 48,
      maxWidth: 48,
    ),
    this.labelText,
    this.validator,
    this.controller,
    this.isLoading = false,
    this.getItemChild,
    this.isDense = true,
    this.isDisabled = false,
    this.menuMaxHeight,
    this.labelSuffixWidget,
    this.labelSide = '',
    this.prefix,
    this.suffix,
    this.required = false,
    this.boxBorder = InputBorder.none,
    this.onTap,
    this.initialValue,
    this.keyboardType,
    this.obscureText,
    this.readOnly,
    this.height,
    this.maxLines,
    this.lines,
    this.maxLength,
    this.type,
    this.marginBottom,
    this.textStyle,
    this.hintStyle,
    this.isRequired = false,
    this.emptyMessage,
  });

  @override
  State<SearchableDropdownButtonFormFieldWidget<T>> createState() =>
      _SearchableDropdownButtonFormFieldWidgetState<T>();
}

class _SearchableDropdownButtonFormFieldWidgetState<T>
    extends State<SearchableDropdownButtonFormFieldWidget<T>> {
  late TextEditingController _searchController;
  late TextEditingController _displayController;
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _displayController = TextEditingController(
      text: widget.value != null && widget.getItemText != null
          ? widget.getItemText!(widget.value as T)
          : '',
    );
    _filteredItems = widget.items ?? [];
  }

  @override
  void didUpdateWidget(
    covariant SearchableDropdownButtonFormFieldWidget<T> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filteredItems = widget.items ?? [];
    }
    if (oldWidget.value != widget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _displayController.text =
            widget.value != null && widget.getItemText != null
                ? widget.getItemText!(widget.value as T)
                : '';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _displayController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    if (widget.items == null) return;
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items!;
      } else {
        _filteredItems = widget.items!
            .where(
              (item) => widget.getItemText!(item).toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      }
    });
  }

  void _showSearchDialog() {
    _searchController.clear();
    _filteredItems = widget.items ?? [];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select ${widget.labelText ?? ''}'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: AppTextStyles.bodySmall,
                      onChanged: (value) {
                        setState(() {
                          _filterItems(value);
                        });
                      },
                    ),
                    const Divider(height: 1, thickness: 0.5),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 300,
                        minHeight: 100,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _filteredItems.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, thickness: 0.25),
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return ListTile(
                            dense: true,
                            title: Text(
                              widget.getItemText!(item),
                              style: AppTextStyles.bodySmall,
                            ),
                            onTap: () {
                              widget.onChanged?.call(item);
                              _displayController.text = widget.getItemText!(
                                item,
                              );
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.labelText!, style: AppTextStyles.bodyLargeMedium),
              if (widget.isRequired)
                Text(
                  ' *',
                  style: AppTextStyles.bodyLargeMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
        if (widget.labelText != null) const VerticalGap(8),
        if (widget.isLoading)
          const DropdownButtonFormFieldLoadingWidget()
        else
          TextFormField(
            controller: _displayController,
            readOnly: true,
            onTap: widget.isDisabled ? null : _showSearchDialog,
            validator: widget.validator != null
                ? (value) => widget.validator!(widget.value)
                : null,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: AppTextStyles.bodySmall,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              errorMaxLines: 2,
              errorStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
              hintText: widget.hintText,
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.tertiary,
              ),
              suffixIcon: SizedBox.square(
                dimension: 18,
                child: Center(
                  child: SvgPictureAssetWidget(
                    AppImages.chevronDownSvg,
                    color: widget.isDisabled
                        ? AppColors.primaryText.withValues(alpha: 0.5)
                        : AppColors.primaryText,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class DropdownButtonFormFieldWidget<T> extends StatelessWidget {
  final T? value;
  final String? hintText;
  final Widget? prefixIcon;
  final bool isLoading;
  final String? labelText;
  final List<T>? items;
  final String Function(T item)? getItemText;
  final BoxConstraints prefixIconConstraints;
  final Widget Function(T item)? getItemChild;
  final void Function(T? item)? onChanged;
  final String? Function(T? item)? validator;
  final TextEditingController? controller;
  final bool isDense;
  final bool isDisabled;
  final double? menuMaxHeight;
  final Widget? labelSuffixWidget;
  final String labelSide;
  final Widget? prefix;
  final Widget? suffix;
  final bool required;
  final InputBorder boxBorder;
  final void Function()? onTap;
  final T? initialValue;
  final TextInputType? keyboardType;
  final bool? obscureText, readOnly;
  final int? maxLines;
  final int? lines;
  final int? maxLength;
  final TextInputType? type;
  final double? marginBottom;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final bool isRequired;
  final double? height;
  final String? emptyMessage;
  const DropdownButtonFormFieldWidget({
    super.key,
    this.value,
    this.hintText,
    this.prefixIcon,
    this.items,
    this.getItemText,
    required this.onChanged,
    this.prefixIconConstraints = const BoxConstraints(
      maxHeight: 48,
      maxWidth: 48,
    ),
    this.labelText,
    this.validator,
    this.controller,
    this.isLoading = false,
    this.getItemChild,
    this.isDense = true,
    this.isDisabled = false,
    this.menuMaxHeight,
    this.labelSuffixWidget,
    this.labelSide = '',
    this.prefix,
    this.suffix,
    this.required = false,
    this.boxBorder = InputBorder.none,
    this.onTap,
    this.initialValue,
    this.keyboardType,
    this.obscureText,
    this.readOnly,
    this.height,
    this.maxLines,
    this.lines,
    this.maxLength,
    this.type,
    this.marginBottom,
    this.textStyle,
    this.hintStyle,
    this.isRequired = false,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null)
          Row(
            children: [
              Flexible(
                child: Text(labelText!, style: AppTextStyles.bodyLargeMedium),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: AppTextStyles.bodyLargeMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
        if (labelText != null) const VerticalGap(8),
        if (isLoading)
          const DropdownButtonFormFieldLoadingWidget()
        else
          IgnorePointer(
            ignoring: isDisabled,
            child: DropdownButtonFormField<T>(
              isExpanded: true,
              isDense: isDense,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: validator,
              initialValue: value,
              menuMaxHeight: menuMaxHeight,
              style: AppTextStyles.bodySmall,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                errorMaxLines: 2,
                errorStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                ),
              ),
              hint: hintText == null
                  ? null
                  : Text(
                      (items?.isEmpty ?? true) &&
                              !isLoading &&
                              emptyMessage != null
                          ? emptyMessage!
                          : hintText!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.tertiary,
                      ),
                    ),
              disabledHint: hintText == null
                  ? null
                  : Text(
                      (items?.isEmpty ?? true) &&
                              !isLoading &&
                              emptyMessage != null
                          ? emptyMessage!
                          : hintText!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.tertiary.withValues(alpha: 0.5),
                      ),
                    ),
              icon: SizedBox.square(
                dimension: 18,
                child: SvgPictureAssetWidget(
                  AppImages.chevronDownSvg,
                  color: _isDisabled()
                      ? AppColors.primaryText.withValues(alpha: 0.5)
                      : AppColors.primaryText,
                ),
              ),
              items: items
                  ?.map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: _getItemChildWidget(e),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
      ],
    );
  }

  Widget _getItemChildWidget(T element) {
    if (getItemChild != null) {
      return getItemChild!(element);
    }
    if (getItemText != null) {
      return Text(
        getItemText!(element),
        style: AppTextStyles.bodySmall, // Smaller text for dropdown items
      );
    }
    return SizedBox.shrink();
  }

  bool _isDisabled() =>
      onChanged == null || (items == null || (items?.isEmpty ?? true));
}

class PasswordTextInputFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool showPassword;
  final String? Function(String?)? validator;
  final void Function()? onSuffixButtonTap;
  final bool isRequired;
  const PasswordTextInputFormField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hintText = 'xxxxxxx',
    required this.showPassword,
    this.onSuffixButtonTap,
    this.validator,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormFieldWidget(
      controller: controller,
      labelText: label,
      hintText: hintText,
      isPasswordTextField: !showPassword,
      maxLines: 1,
      isRequired: isRequired,
      validator: validator,
      suffixIcon: IconButton(
        onPressed: onSuffixButtonTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(
          showPassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: AppColors.tertiary,
          size: 20,
        ),
      ),
    );
  }
}
