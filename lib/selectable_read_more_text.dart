library selectable_read_more_text;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'enumerations/enumerations.dart';


class SelectableReadMoreText extends StatefulWidget {
  const SelectableReadMoreText(
      this.text, {
        Key? key,
        this.preDataText,
        this.postDataText,
        this.preDataTextStyle,
        this.postDataTextStyle,
        this.trimExpandedText = 'show less',
        this.trimCollapsedText = 'read more',
        this.colorClickableText,
        this.trimLength = 200,
        this.trimLines = 3,
        this.trimMode = TrimType.Length,
        this.style,
        this.textAlign,
        this.textDirection,
        this.locale,
        this.textScaleFactor,
        this.semanticsLabel,
        this.moreStyle,
        this.lessStyle,
        this.delimiter = '$_kEllipsis ',
        this.delimiterStyle,
        this.callback,
        this.onLinkPressed,
        this.linkTextStyle,
      }) : super(key: key);

  /// Used on TrimMode.Length
  final int trimLength;

  /// Used on TrimMode.Lines
  final int trimLines;

  /// Determines the type of trim. TrimMode.Length takes into account
  /// the number of letters, while TrimMode.Lines takes into account
  /// the number of lines
  final TrimType trimMode;

  /// TextStyle for expanded text
  final TextStyle? moreStyle;

  /// TextStyle for compressed text
  final TextStyle? lessStyle;

  /// TextSpan used before the data any heading or something
  final String? preDataText;

  /// TextSpan used after the data end or before the more/less
  final String? postDataText;

  /// TextSpan used before the data any heading or something
  final TextStyle? preDataTextStyle;

  /// TextSpan used after the data end or before the more/less
  final TextStyle? postDataTextStyle;

  ///Called when state change between expanded/compress
  final Function(bool val)? callback;

  final ValueChanged<String>? onLinkPressed;

  final TextStyle? linkTextStyle;

  final String delimiter;
  final String text;
  final String trimExpandedText;
  final String trimCollapsedText;
  final Color? colorClickableText;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final double? textScaleFactor;
  final String? semanticsLabel;
  final TextStyle? delimiterStyle;

  @override
  SelectableReadMoreTextState createState() => SelectableReadMoreTextState();
}

const String _kEllipsis = '\u2026';

const String _kLineSeparator = '\u2028';

class SelectableReadMoreTextState extends State<SelectableReadMoreText> {
  bool _readMore = true;

  void _onTapLink() {
    setState(() {
      _readMore = !_readMore;
      widget.callback?.call(_readMore);
    });
  }

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle? effectiveTextStyle = widget.style;
    if (widget.style?.inherit ?? false) {
      effectiveTextStyle = defaultTextStyle.style.merge(widget.style);
    }

    final textAlign =
        widget.textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start;
    final textDirection = widget.textDirection ?? Directionality.of(context);
    final textScaleFactor =
        widget.textScaleFactor ?? MediaQuery.textScaleFactorOf(context);
    final overflow = defaultTextStyle.overflow;
    final locale = widget.locale ?? Localizations.maybeLocaleOf(context);

    final colorClickableText =
        widget.colorClickableText ?? Theme.of(context).colorScheme.secondary;
    final defaultLessStyle = widget.lessStyle ??
        effectiveTextStyle?.copyWith(color: colorClickableText);
    final defaultMoreStyle = widget.moreStyle ??
        effectiveTextStyle?.copyWith(color: colorClickableText);
    final defaultDelimiterStyle = widget.delimiterStyle ?? effectiveTextStyle;

    final TextSpan link = TextSpan(
      text: _readMore ? widget.trimCollapsedText : widget.trimExpandedText,
      style: _readMore ? defaultMoreStyle : defaultLessStyle,
      recognizer: TapGestureRecognizer()..onTap = _onTapLink,
    );

    final TextSpan delimiter = TextSpan(
      text: _readMore
          ? widget.trimCollapsedText.isNotEmpty
          ? widget.delimiter
          : ''
          : '',
      style: defaultDelimiterStyle,
      recognizer: TapGestureRecognizer()..onTap = _onTapLink,
    );

    Widget result = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        assert(constraints.hasBoundedWidth);
        final double maxWidth = constraints.maxWidth;

        TextSpan? preTextSpan;
        TextSpan? postTextSpan;
        if (widget.preDataText != null) {
          preTextSpan = TextSpan(
            text: "${widget.preDataText!} ",
            style: widget.preDataTextStyle ?? effectiveTextStyle,
          );
        }
        if (widget.postDataText != null) {
          postTextSpan = TextSpan(
            text: " ${widget.postDataText!}",
            style: widget.postDataTextStyle ?? effectiveTextStyle,
          );
        }

        // Create a TextSpan with data
        final text =
        TextSpan(
          children: <InlineSpan>[
            if (preTextSpan != null) preTextSpan,
            TextSpan(text: widget.text, style: effectiveTextStyle),
            if (postTextSpan != null) postTextSpan,

          ],

        );

        // Layout and measure link
        final TextPainter textPainter = TextPainter(
          text: link,
          textAlign: textAlign,
          textDirection: textDirection,
          textScaleFactor: textScaleFactor,
          maxLines: widget.trimLines,
          ellipsis: overflow == TextOverflow.ellipsis ? widget.delimiter : null,
          locale: locale,
        );
        textPainter.layout(minWidth: 0, maxWidth: maxWidth);
        final linkSize = textPainter.size;

        // Layout and measure delimiter
        textPainter.text = delimiter;
        textPainter.layout(minWidth: 0, maxWidth: maxWidth);
        final delimiterSize = textPainter.size;

        // Layout and measure text
        textPainter.text = text ;
        textPainter.layout(minWidth: constraints.minWidth, maxWidth: maxWidth);
        final textSize = textPainter.size;

        // Get the endIndex of data
        bool linkLongerThanLine = false;
        int endIndex;

        if (linkSize.width < maxWidth) {
          final readMoreSize = linkSize.width + delimiterSize.width;
          final pos = textPainter.getPositionForOffset(Offset(
            textDirection == TextDirection.rtl
                ? readMoreSize
                : textSize.width - readMoreSize,
            textSize.height,
          ));
          endIndex = textPainter.getOffsetBefore(pos.offset) ?? 0;
        } else {
          final pos = textPainter.getPositionForOffset(
            textSize.bottomLeft(Offset.zero),
          );
          endIndex = pos.offset;
          linkLongerThanLine = true;
        }

        SelectableText textSpan;
        switch (widget.trimMode) {
          case TrimType.Length:
            if (widget.trimLength < widget.text.length) {
              textSpan = _buildText(
                data: _readMore
                    ? widget.text.substring(0, widget.trimLength)
                    : widget.text,
                textStyle: effectiveTextStyle,
                linkTextStyle: effectiveTextStyle?.copyWith(
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
                onPressed: widget.onLinkPressed,
                children: [delimiter, link],
              );
            } else {
              textSpan = _buildText(
                data: widget.text,
                textStyle: effectiveTextStyle,
                linkTextStyle: effectiveTextStyle?.copyWith(
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
                onPressed: widget.onLinkPressed,
                children: [],
              );
            }
            break;
          case TrimType.Line:
            if (textPainter.didExceedMaxLines) {
              textSpan = _buildText(
                data: _readMore
                    ? widget.text.substring(0, endIndex) +
                    (linkLongerThanLine ? _kLineSeparator : '')
                    : widget.text,
                textStyle: effectiveTextStyle,
                linkTextStyle: effectiveTextStyle?.copyWith(
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
                onPressed: widget.onLinkPressed,
                children: [delimiter, link],
              );
            } else {
              textSpan = _buildText(
                data: widget.text,
                textStyle: effectiveTextStyle,
                linkTextStyle: effectiveTextStyle?.copyWith(
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
                onPressed: widget.onLinkPressed,
                children: [],
              );
            }
            break;
          default:
            throw Exception(
              'TrimMode type: ${widget.trimMode} is not supported',
            );
        }

        return SelectableText.rich(
          TextSpan(
            children: [
              if (preTextSpan != null) preTextSpan,
              textSpan.textSpan!,
              if (postTextSpan != null) postTextSpan,
            ],
          ),
          textAlign: textAlign,
          textDirection: textDirection,
          textScaleFactor: textScaleFactor,
        );
      },
    );
    if (widget.semanticsLabel != null) {
      result = Semantics(
        textDirection: widget.textDirection,
        label: widget.semanticsLabel,
        child: ExcludeSemantics(
          child: result,
        ),
      );
    }
    return result;
  }

  SelectableText _buildText({
    required String data,
    TextStyle? textStyle,
    TextStyle? linkTextStyle,
    ValueChanged<String>? onPressed,
    required List<TextSpan> children,
  }) {
    final RegExp exp =
    RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');

    final List<TextSpan> contents = [];

    while (exp.hasMatch(data)) {
      final match = exp.firstMatch(data);

      final firstTextPart = data.substring(0, match!.start);
      final linkTextPart = data.substring(match.start, match.end);

      contents.add(
        TextSpan(
          text: firstTextPart,
        ),
      );
      contents.add(
        TextSpan(
          text: linkTextPart,
          style: linkTextStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => onPressed?.call(
              linkTextPart.trim(),
            ),
        ),
      );
      data = data.substring(match.end, data.length);
    }
    contents.add(
      TextSpan(
        text: data,
      ),
    );
    return SelectableText.rich(TextSpan(
      children: contents..addAll(children),
      style: textStyle,
    ));
  }
}