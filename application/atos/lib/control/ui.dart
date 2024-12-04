import 'package:flutter/material.dart';

class CustomedButton extends StatelessWidget {
  final String text;
  final Color buttonColor;
  final Color textColor;
  final VoidCallback? onTap; // Add onTap callback

  const CustomedButton({
    super.key,
    required this.text,
    required this.buttonColor,
    required this.textColor,
    this.onTap, // Make onTap required
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Assign the onTap callback
      child: Container(
        width: 320,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: buttonColor,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShortInputText extends InputDecoration {
  final String hint;

  ShortInputText({
    required this.hint,
  }) : super(
          labelStyle: TextStyle(color: Color.fromRGBO(42, 52, 110, 1)),
          labelText: hint,
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xffC0B4B2),
              width: 2,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color.fromRGBO(42, 52, 110, 1),
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.only(
            left: 8,
          ),
          constraints: BoxConstraints(
            maxHeight: 50.0,
            maxWidth: 250.0,
          ),
        );
}

class ObscuringTextEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    var displayValue = '•' * value.text.length;
    if (!value.composing.isValid || !withComposing) {
      return TextSpan(style: style, text: displayValue);
    }
    final TextStyle composingStyle =
        (style ?? DefaultTextStyle.of(context).style).merge(
      const TextStyle(decoration: TextDecoration.underline),
    );
    return TextSpan(
      style: style,
      children: <TextSpan>[
        TextSpan(text: displayValue.substring(0, value.composing.start)),
        TextSpan(
          style: composingStyle,
          text: displayValue.substring(
              value.composing.start, value.composing.end),
        ),
        TextSpan(text: displayValue.substring(value.composing.end)),
      ],
    );
  }
}

class ManageSizedBox extends SizedBox {
  final Widget? content;
  final double boxHeight;
  ManageSizedBox({super.key, required this.content, required this.boxHeight})
      : super(
          width: double.infinity,
          height: boxHeight,
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: content,
          ),
        );
}
