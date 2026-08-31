import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:material_ui/material_ui.dart';

class SliderDialog extends StatefulWidget {
  const SliderDialog({
    super.key,
    required this.value,
    required this.title,
    required this.min,
    required this.max,
    this.divisions,
    this.suffix = '',
    this.precise = 1,
    this.manualInput = false,
  });

  final double value;
  final Widget title;
  final double min;
  final double max;
  final int? divisions;
  final String suffix;
  final int precise;
  final bool manualInput;

  @override
  State<SliderDialog> createState() => _SliderDialogState();
}

class _SliderDialogState extends State<SliderDialog> {
  late double _tempValue;
  late final TextEditingController _inputController;
  String? _inputError;

  @override
  void initState() {
    super.initState();
    _tempValue = widget.value;
    _inputController = TextEditingController(
      text: widget.value.toStringAsFixed(widget.precise),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _setInput(String text) {
    final value = double.tryParse(text);
    final valid =
        value != null &&
        value.isFinite &&
        value >= widget.min &&
        value <= widget.max;
    setState(() {
      _inputError = valid ? null : '请输入 ${widget.min}~${widget.max} 范围内的数字';
      if (valid) {
        _tempValue = value.toPrecision(widget.precise);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title,
      contentPadding: const .only(top: 20, left: 8, right: 8, bottom: 8),
      content: SizedBox(
        height: widget.manualInput ? 120 : 40,
        child: Column(
          children: [
            Slider(
              value: _tempValue,
              min: widget.min,
              max: widget.max,
              divisions: widget.divisions,
              label:
                  '${_tempValue.toStringAsFixed(widget.precise)}${widget.suffix}',
              onChanged: (double value) {
                setState(() {
                  _tempValue = value.toPrecision(widget.precise);
                  _inputController.text = _tempValue.toStringAsFixed(
                    widget.precise,
                  );
                  _inputError = null;
                });
              },
            ),
            if (widget.manualInput)
              TextField(
                controller: _inputController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: '手动输入',
                  errorText: _inputError,
                ),
                onChanged: _setInput,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text(
            '取消',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        TextButton(
          onPressed: _inputError == null
              ? () => Navigator.pop(context, _tempValue)
              : null,
          child: const Text('确定'),
        ),
      ],
    );
  }
}
