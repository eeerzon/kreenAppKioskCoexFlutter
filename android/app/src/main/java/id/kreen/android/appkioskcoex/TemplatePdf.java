package id.kreen.android.appkioskcoex;

import android.content.Context;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.Typeface;
import android.graphics.pdf.PdfDocument;
import android.util.Log;

import com.google.zxing.BarcodeFormat;
import com.journeyapps.barcodescanner.BarcodeEncoder;

import org.json.JSONArray;
import org.json.JSONTokener;

import java.io.Console;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.List;
import java.util.Set;
import java.util.HashSet;
import java.util.Arrays;

import java.util.Map;



public class TemplatePdf {

    public static void buildPdf1(Context context, String filename, String title, String subtitle, String id_ticket, String jobtitle, int event_buyer, String answer) { // buyer format

        Rect bounds = new Rect();
        int pageWidth = 250;
        int pageheight = 180;
        int pathHeight = 2;

        String _title = title;
        String _subtitle = (event_buyer > 0 || !subtitle.equals("-")) ? subtitle : " ";
        String _jobtitle = (event_buyer > 0 || !jobtitle.equals("-")) ? jobtitle : " ";

        String _filename = filename + ".pdf";
        PdfDocument myPdfDocument = new PdfDocument();
        Paint paint = new Paint();
        PdfDocument.PageInfo myPageInfo = new PdfDocument.PageInfo.Builder(pageWidth, pageheight, 1).create();
        PdfDocument.Page documentPage = myPdfDocument.startPage(myPageInfo);
        Canvas canvas = documentPage.getCanvas();

        int textSize = 20;// 20
        paint.setTextSize(textSize);
        paint.setTypeface(Typeface.defaultFromStyle(Typeface.NORMAL));
        paint.setColor(Color.BLACK);
        paint.setTextAlign(Paint.Align.CENTER);
        paint.getTextBounds(_title, 0, _title.length(), bounds);

//        String strText=title+"\nQR Code";
        String strText = "";
        if (event_buyer > 0) {
            strText = _subtitle + "\n" + _title + "\n" + _jobtitle;
        } else {
            strText = _title;
        }

        String[] str = strText.split("\n");

        Log.e("TAG", "buildPdf2: " + str.length);

        int x_ = (pageWidth) / 2;
        int y_ = (((canvas.getHeight()) - (textSize * str.length) - (80 - textSize)) / 2);
        int i = 0;
        for (String line : strText.split("\n")) {
            if (i == 0) {
                paint.setTextSize(18);
            } else {
                paint.setTextSize(textSize);
            }
            canvas.drawText(line, x_, y_, paint);
            y_ += paint.descent() - paint.ascent();
            i++;
        }

        int mRight = canvas.getClipBounds().right;
        int mLeft = canvas.getClipBounds().left;
        int mBottom = canvas.getClipBounds().bottom;
        int mTop = canvas.getClipBounds().top;

        float y_codeTitle1 = (y_ - ((paint.descent() - paint.ascent())));
        float y_codeTitle2 = y_;
        paint.setTextSize(12);
        paint.setColor(Color.GRAY);
        paint.setTextAlign(Paint.Align.RIGHT);
        paint.setTypeface(Typeface.defaultFromStyle(Typeface.BOLD));
//        canvas.drawText("QR Code", mRight, y_codeTitle, paint);
//        y_ += paint.descent() - paint.ascent();

        if ((!answer.equals("")) && (!answer.equals("-"))) {

            Resources res = context.getResources();
            Bitmap bitmapGift = BitmapFactory.decodeResource(res, R.drawable.icon_gift);
            Bitmap bGift = (Bitmap.createScaledBitmap(bitmapGift, 35, 35, false));
            canvas.drawBitmap(bGift, mLeft + 10, y_ - ((paint.descent() - paint.ascent())) + 90 - 35, paint);

        }

        // Gegenate qrcode
        try {
            BarcodeEncoder barcodeEncoder = new BarcodeEncoder();
            Bitmap bitmap = barcodeEncoder.encodeBitmap(id_ticket, BarcodeFormat.QR_CODE, 200, 200);
            Bitmap b = (Bitmap.createScaledBitmap(bitmap, 100, 100, false));

            canvas.drawBitmap(b, mRight - 95, (y_ - ((paint.descent() - paint.ascent())) + 3), paint);
        } catch (Exception e) {

        }

        canvas.drawText("QR Code", mRight - 10, y_codeTitle2, paint);
//        canvas.drawText("QR Code", mRight-10, y_codeTitle1+14+3, paint);

        myPdfDocument.finishPage(documentPage);

        String filepath = null;
        try {
            File mypath = new File((context).getExternalFilesDir(null).toString() + "/" + _filename);
            filepath = mypath.toString();
            myPdfDocument.writeTo(new FileOutputStream(mypath));
            Log.d("ez_UserAreaActivity", "Success create pdf");

            /*FragmentTransaction ft = getParentFragmentManager().beginTransaction();

            ft.replace(R.id.fragment_container, new ThreeManualFragment());
            ft.commit();*/

        } catch (FileNotFoundException e) {
            Log.d("ez_UserAreaActivity", "File not found exception");
        } catch (IOException e) {
            Log.d("ez_UserAreaActivity", "IOException");
        }


        // close the document
        myPdfDocument.close();

    }

    // Template ticket no qrcode
    public static String buildPdf2(Context context, String filename, String title, String subtitle, String id_ticket, String jobtitle, int event_buyer, String answer) {
        Rect bounds = new Rect();
        int pageWidth = 250;
        int pageHeight = 100;
        int lineSpacing = 6; // Add 6px space between lines

        String _title = title;
        String _subtitle = (event_buyer > 0 || !subtitle.equals("-")) ? subtitle : " ";
        String _jobtitle = (event_buyer > 0 || !jobtitle.equals("-")) ? jobtitle : " ";

        String _filename = filename + ".pdf";
        PdfDocument myPdfDocument = new PdfDocument();
        Paint paint = new Paint();
        PdfDocument.PageInfo myPageInfo = new PdfDocument.PageInfo.Builder(pageWidth, pageHeight, 1).create();
        PdfDocument.Page documentPage = myPdfDocument.startPage(myPageInfo);
        Canvas canvas = documentPage.getCanvas();

        int textSize = 20; // 20
        paint.setTextSize(textSize);
        paint.setTypeface(Typeface.defaultFromStyle(Typeface.NORMAL));
        paint.setColor(Color.BLACK);
        paint.setTextAlign(Paint.Align.CENTER);

        String strText = "";
        if (event_buyer > 0) {
            strText = _subtitle + "\n" + _title + "\n" + _jobtitle;
        } else {
            strText = _title;
        }

        String[] str = strText.split("\n");

        Log.e("TAG", "buildPdf2: " + str.length);

        int x_ = pageWidth / 2;
        // Calculate total height of the text block including line spacing
        int totalTextHeight = 0;
        for (String line : str) {
            paint.getTextBounds(line, 0, line.length(), bounds);
            totalTextHeight += bounds.height();
        }
        totalTextHeight += (str.length - 1) * lineSpacing; // Add 6px for each line spacing except the last line
        // Starting y position to center the text block
        int y_ = (pageHeight - totalTextHeight) / 2;

        for (String line : str) {
            paint.getTextBounds(line, 0, line.length(), bounds);
            y_ += bounds.height();
            canvas.drawText(line, x_, y_, paint);
            y_ += lineSpacing; // Add 6px space between lines
        }

        myPdfDocument.finishPage(documentPage);

        String filepath = null;

        try {
            File mypath = new File((context).getExternalFilesDir(null).toString() + "/" + _filename);
            filepath = mypath.toString();
            myPdfDocument.writeTo(new FileOutputStream(mypath));
            Log.d("ez_UserAreaActivity", "Success create pdf");
        } catch (FileNotFoundException e) {
            Log.d("ez_UserAreaActivity", "File not found exception");
        } catch (IOException e) {
            Log.d("ez_UserAreaActivity", "IOException");
        }

        // Close the document
        myPdfDocument.close();

        return filepath;
    }

    public static String buildPdfDynamic(Context context, String filename, String id_ticket, List<String> detailValues) {
        Rect bounds = new Rect();
        int pageWidth = 250;
        int pageHeight = 80;
        int lineSpacing = 6; // Add 6px space between lines

        String _filename = filename + ".pdf";
        PdfDocument myPdfDocument = new PdfDocument();
        Paint paint = new Paint();
        PdfDocument.PageInfo myPageInfo = new PdfDocument.PageInfo.Builder(pageWidth, pageHeight, 1).create();
        PdfDocument.Page documentPage = myPdfDocument.startPage(myPageInfo);
        Canvas canvas = documentPage.getCanvas();

        int textSize = 16; // 20
        paint.setTextSize(textSize);
        paint.setTypeface(Typeface.defaultFromStyle(Typeface.NORMAL));
        paint.setColor(Color.BLACK);
        paint.setTextAlign(Paint.Align.CENTER);

        // Build strText from detailValues
        StringBuilder strTextBuilder = new StringBuilder();
        for (String value : detailValues) {
            strTextBuilder.append(value).append("\n");
        }
        String strText = strTextBuilder.toString();

        String[] str = strText.split("\n");

        Log.e("TAG", "buildPdf2: " + str.length);

        int x_ = pageWidth / 2;
        // Calculate total height of the text block including line spacing
        int totalTextHeight = 0;
        for (String line : str) {
            paint.getTextBounds(line, 0, line.length(), bounds);
            totalTextHeight += bounds.height();
        }
        totalTextHeight += (str.length - 1) * lineSpacing; // Add 6px for each line spacing except the last line
        // Starting y position to center the text block
        int y_ = (pageHeight - totalTextHeight) / 2;

        for (String line : str) {
            paint.getTextBounds(line, 0, line.length(), bounds);
            y_ += bounds.height();
            canvas.drawText(line, x_, y_, paint);
            y_ += lineSpacing; // Add 6px space between lines
        }

        myPdfDocument.finishPage(documentPage);

        String filepath = null;

        try {
            File mypath = new File((context).getExternalFilesDir(null).toString() + "/" + _filename);
            filepath = mypath.toString();
            myPdfDocument.writeTo(new FileOutputStream(mypath));
            Log.d("ez_UserAreaActivity", "Success create pdf");
        } catch (FileNotFoundException e) {
            Log.d("ez_UserAreaActivity", "File not found exception");
        } catch (IOException e) {
            Log.d("ez_UserAreaActivity", "IOException");
        }

        // Close the document
        myPdfDocument.close();

        return filepath;
    }

    public static String buildPdfDynamicQr(Context context, String filename, String id_ticket, List<String> detailValues, String answer) { // buyer format

        Rect bounds = new Rect();
        int pageWidth = 250;
        int pageheight = 180;
        int pathHeight = 2;

        String _filename = filename + ".pdf";
        PdfDocument myPdfDocument = new PdfDocument();
        Paint paint = new Paint();
        PdfDocument.PageInfo myPageInfo = new PdfDocument.PageInfo.Builder(pageWidth, pageheight, 1).create();
        PdfDocument.Page documentPage = myPdfDocument.startPage(myPageInfo);
        Canvas canvas = documentPage.getCanvas();

        int textSize = 16;// 20
        paint.setTextSize(textSize);
        paint.setTypeface(Typeface.defaultFromStyle(Typeface.NORMAL));
        paint.setColor(Color.BLACK);
        paint.setTextAlign(Paint.Align.CENTER);
//        paint.getTextBounds(_title, 0, _title.length(), bounds);

//        String strText=title+"\nQR Code";
//        String strText="";
        // Build strText from detailValues
        StringBuilder strTextBuilder = new StringBuilder();
        for (String value : detailValues) {
            strTextBuilder.append(value).append("\n");
        }
        String strText = strTextBuilder.toString();

        String[] str = strText.split("\n");

        Log.e("TAG", "buildPdf2: " + str.length);

        int x_ = (pageWidth) / 2;
        int y_ = (((canvas.getHeight()) - (textSize * str.length) - (80 - textSize)) / 2);
        int i = 0;
        for (String line : strText.split("\n")) {
            if (i == 0) {
                paint.setTextSize(16); //18
            } else {
                paint.setTextSize(textSize);
            }
            canvas.drawText(line, x_, y_, paint);
            y_ += paint.descent() - paint.ascent();
            i++;
        }

        int mRight = canvas.getClipBounds().right;
        int mLeft = canvas.getClipBounds().left;
        int mBottom = canvas.getClipBounds().bottom;
        int mTop = canvas.getClipBounds().top;

        float y_codeTitle1 = (y_ - ((paint.descent() - paint.ascent())));
        float y_codeTitle2 = y_;
        paint.setTextSize(12);
        paint.setColor(Color.GRAY);
        paint.setTextAlign(Paint.Align.RIGHT);
        paint.setTypeface(Typeface.defaultFromStyle(Typeface.BOLD));
//        canvas.drawText("QR Code", mRight, y_codeTitle, paint);
//        y_ += paint.descent() - paint.ascent();

        if ((!answer.equals("")) && (!answer.equals("-"))) {

            Resources res = context.getResources();
            Bitmap bitmapGift = BitmapFactory.decodeResource(res, R.drawable.icon_gift);
            Bitmap bGift = (Bitmap.createScaledBitmap(bitmapGift, 35, 35, false));
            canvas.drawBitmap(bGift, mLeft + 10, y_ - ((paint.descent() - paint.ascent())) + 90 - 35, paint);

        }

        // Gegenate qrcode
        try {
            BarcodeEncoder barcodeEncoder = new BarcodeEncoder();
            Bitmap bitmap = barcodeEncoder.encodeBitmap(id_ticket, BarcodeFormat.QR_CODE, 200, 200);
            Bitmap b = (Bitmap.createScaledBitmap(bitmap, 100, 100, false));

            canvas.drawBitmap(b, mRight - 95, (y_ - ((paint.descent() - paint.ascent())) + 3), paint);
        } catch (Exception e) {

        }

        canvas.drawText("QR Code", mRight - 10, y_codeTitle2, paint);
//        canvas.drawText("QR Code", mRight-10, y_codeTitle1+14+3, paint);

        myPdfDocument.finishPage(documentPage);

        String filepath = null;
        try {
            File mypath = new File((context).getExternalFilesDir(null).toString() + "/" + _filename);
            filepath = mypath.toString();
            myPdfDocument.writeTo(new FileOutputStream(mypath));
            Log.d("ez_UserAreaActivity", "Success create pdf");

            /*FragmentTransaction ft = getParentFragmentManager().beginTransaction();

            ft.replace(R.id.fragmentContainer, new ThreeManualFragment());
            ft.commit();*/

        } catch (FileNotFoundException e) {
            Log.d("ez_UserAreaActivity", "File not found exception");
        } catch (IOException e) {
            Log.d("ez_UserAreaActivity", "IOException");
        }


        // close the document
        myPdfDocument.close();

        return filepath;
    }

    public static String buildPdfDynamicQrCenter(Context context, String filename, String id_ticket, List<OrderFormModel> formValues, String answer, String full_name, String email) {
        Rect bounds = new Rect();
        int pageWidth = 250;
        int pageHeight = 180;
        int pathHeight = 2;

        String _filename = filename + ".pdf";
        PdfDocument myPdfDocument = new PdfDocument();
        Paint paint = new Paint();
        PdfDocument.PageInfo myPageInfo = new PdfDocument.PageInfo.Builder(pageWidth, pageHeight, 1).create();
        PdfDocument.Page documentPage = myPdfDocument.startPage(myPageInfo);
        Canvas canvas = documentPage.getCanvas();

        int textSize = 16; // 20 //16
        paint.setTextSize(textSize);
        paint.setTypeface(Typeface.defaultFromStyle(Typeface.NORMAL));
        paint.setColor(Color.BLACK);
        paint.setTextAlign(Paint.Align.CENTER);

        StringBuilder strTextBuilder = new StringBuilder();

        String company = "";
        String job = "";
        boolean hasRegistrationCode = false;
        String regCode = "";

        if (formValues.isEmpty()) {
            strTextBuilder.append(full_name).append("\n");
            strTextBuilder.append(email).append("\n\n");
        } else {
            for (OrderFormModel value : formValues) {
                if (value.getQuestion().equals("Company Name (Nama Perusahaan)")) {
                    company = cleanAnswer(value.getAnswer());
                } else if (value.getQuestion().equals("Job Title (Nama Pekerjaan)")) {
                    job = cleanAnswer(value.getAnswer());
                } else if (value.getQuestion().equals("Registration Code (Kode Registrasi)")) {
                    hasRegistrationCode = true;
                    regCode = cleanAnswer(value.getAnswer());
                }
            }

            if (company.equals("")) {
                strTextBuilder.append(full_name).append("\n");
                strTextBuilder.append(email).append("\n\n");
            } else {
                strTextBuilder.append(company).append("\n");
                strTextBuilder.append(full_name).append("\n");
                strTextBuilder.append(job).append("\n\n");
            }

        }

        // Tambah section "Full name"
//        strTextBuilder.append("Full name").append("\n");
//        strTextBuilder.append(full_name).append("\n\n");
//
//        // Tambah section "email"
//        strTextBuilder.append("Email").append("\n");
//        strTextBuilder.append(email).append("\n\n");
//
//        // Tambah section "Question : Answer"
//        for (OrderFormModel value : formValues) {
//            strTextBuilder.append(value.getQuestion())
//                    .append("\n")
//                    .append(value.getAnswer())
//                    .append("\n");
//        }

        String[] str = strTextBuilder.toString().split("\n");


        Log.e("TAG", "buildPdf2: " + str.length);

        int x_ = pageWidth / 2;
        int y_ = (canvas.getHeight() - (textSize * str.length) - (80 - textSize)) / 2;
        int i = 0;

        for (String line : str) {
            if (line.equals("Full name") || line.equals("Question : Answer") || line.equals("Email")) {
                paint.setTypeface(Typeface.defaultFromStyle(Typeface.BOLD));
                paint.setTextSize(16);
            } else {
                paint.setTypeface(Typeface.defaultFromStyle(Typeface.NORMAL));
                paint.setTextSize(16); //14
            }

            canvas.drawText(line, x_, y_, paint);
            y_ += paint.descent() - paint.ascent();
            i++;
        }

        int mRight = canvas.getClipBounds().right;
        int mLeft = canvas.getClipBounds().left;
        int mBottom = canvas.getClipBounds().bottom;
        int mTop = canvas.getClipBounds().top;

        float y_codeTitle1 = y_ - (paint.descent() - paint.ascent());
        float y_codeTitle2 = y_;
        paint.setTextSize(16); //14
        paint.setColor(Color.GRAY);
        paint.setTextAlign(Paint.Align.CENTER);
        paint.setTypeface(Typeface.defaultFromStyle(Typeface.BOLD));

        if ((!answer.equals("")) && (!answer.equals("-"))) {
            Resources res = context.getResources();
            Bitmap bitmapGift = BitmapFactory.decodeResource(res, R.drawable.icon_gift);
            Bitmap bGift = Bitmap.createScaledBitmap(bitmapGift, 35, 35, false);
            canvas.drawBitmap(bGift, mLeft + 10, y_ - (paint.descent() - paint.ascent()) + 90 - 35, paint);
        }

        // Tambahkan ikon gift (hanya jika ada Registration Code)

        // List referral codes valid
        Set<String> referralCodes = new HashSet<>(Arrays.asList(
                "Kode Referral",
                "AZ01TA",
                "RA02KB",
                "NP03KG",
                "AP04WD",
                "MS05RE",
                "MI06UN",
                "DA07HV",
                "AF08ZZ",
                "CM09JZ",
                "AG10CY",
                "CH11WX",
                "SA12MO",
                "AR13YU",
                "MG14QC",
                "NH15DL",
                "RP16YI",
                "MZ17WW",
                "SR18UQ",
                "CO19YP",
                "AI20CI",
                "AA21FS",
                "NA22KP",
                "AC23WR",
                "AP24AD",
                "IZ25NR",
                "MA26KW",
                "TL27LX",
                "EF28JD",
                "MR29EN",
                "GS30JO",
                "SA31EO",
                "NN32KD",
                "PO33GL",
                "MR34FZ",
                "FW35AV",
                "DP36OE",
                "AF37OZ",
                "FC38KS",
                "AA39PW",
                "DS40NT",
                "AN41XN",
                "KN42UJ",
                "ZH43FW",
                "NZ44AM",
                "KN45UO",
                "BAHASA IBU BAHAGIA COMMUNITY",
                "BAHASA IBU COMMUNITY",
                "BIB",
                "BIBXIMKDS",
                "PETCAPET"
        ));

        if (hasRegistrationCode && referralCodes.contains(regCode.trim())) {
            try {
                Bitmap bitmapGift = BitmapFactory.decodeResource(context.getResources(), R.drawable.icon_gift);
                Bitmap bGift = Bitmap.createScaledBitmap(bitmapGift, 35, 35, false);
                // kiri bawah
                int giftX = 15;
                int giftY = pageHeight - bGift.getHeight() - 15;
                canvas.drawBitmap(bGift, giftX, giftY, paint);
            } catch (Exception e) {
                Log.e("PDF", "Error drawing gift icon", e);
            }
        }

        // Generate QR code
        try {
            BarcodeEncoder barcodeEncoder = new BarcodeEncoder();
            Bitmap bitmap = barcodeEncoder.encodeBitmap(id_ticket, BarcodeFormat.QR_CODE, 200, 200);
            Bitmap b = Bitmap.createScaledBitmap(bitmap, 80, 80, false);

            int qrX = pageWidth - b.getWidth() - 15;
            int qrY = pageHeight - b.getHeight() - 15;
            canvas.drawBitmap(b, qrX, qrY, paint);
        } catch (Exception e) {
            Log.e("QRCode", "Error generating QR code", e);
        }

//        canvas.drawText("QR Code", mRight, y_codeTitle2, paint);

        myPdfDocument.finishPage(documentPage);

        String filepath = null;
        try {
            File mypath = new File(context.getExternalFilesDir(null).toString() + "/" + _filename);
            filepath = mypath.toString();
            myPdfDocument.writeTo(new FileOutputStream(mypath));
            Log.d("ez_UserAreaActivity", "Success create pdf");
        } catch (FileNotFoundException e) {
            Log.d("ez_UserAreaActivity", "File not found exception");
        } catch (IOException e) {
            Log.d("ez_UserAreaActivity", "IOException");
        }

        // Close the document
        myPdfDocument.close();

        return filepath;
    }

    public static String cleanAnswer(String raw) {
        if (raw == null || raw.trim().isEmpty() || raw.equals("null")) {
            return "";
        }

        String trimmed = raw.trim();

        try {
            if (trimmed.startsWith("[")) {
                // Bentuk array: [...]
                JSONArray arr = new JSONArray(trimmed);
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < arr.length(); i++) {
                    if (i > 0) {
                        sb.append(", ");
                    }
                    sb.append(arr.optString(i));
                }
                return sb.toString();

            } else if (trimmed.startsWith("\"") && trimmed.endsWith("\"")) {
                // Bentuk string ber-quote ganda: "\"xxx\""
                Object value = new JSONTokener(trimmed).nextValue();
                return String.valueOf(value);

            } else {
                // String biasa
                return trimmed;
            }
        } catch (Exception e) {
            // fallback kalau parsing gagal, buang quote manual saja
            return trimmed.replace("\"", "");
        }
    }

}
