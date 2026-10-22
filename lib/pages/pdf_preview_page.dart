import 'dart:typed_data';

import 'package:appkioskcoex/helper/global_widget.dart';
import 'package:appkioskcoex/models/response_model.dart';
import 'package:appkioskcoex/services/printer_service.dart';
import 'package:flutter/material.dart';

/// PdfPreviewActivity.java -> activity_pdf_preview.xml
/// (dibuka dari btnPrintPreview TwoManual2Fragment yang visibility-nya GONE)
class PdfPreviewPage extends StatefulWidget {
  // getIntent().getStringExtra(...) / getSerializableExtra("formValues")
  final String? fullName;
  final String? email;
  final String? idTicket;
  final String? answer;
  final List<OrderFormModel>? formValues;

  const PdfPreviewPage({super.key, this.fullName, this.email, this.idTicket, this.answer, this.formValues});

  @override
  State<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> {
  Uint8List? qr;

  @override
  void initState() {
    super.initState();
    PrinterService.encodeQrPng(widget.idTicket, 400).then((bytes) {
      if (mounted) setState(() => qr = bytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(width: 200, height: 200, child: qr == null ? null : Image.memory(qr!, fit: BoxFit.contain)),
              DetailList(fullname: widget.fullName, email: widget.email, details: widget.formValues),
            ],
          ),
        ),
      ),
    );
  }
}
