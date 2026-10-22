package id.kreen.android.appkioskcoex;

import android.content.Context;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;

import static android.graphics.Paint.ANTI_ALIAS_FLAG;
import android.graphics.Rect;
import android.graphics.Typeface;
import android.graphics.pdf.PdfDocument;
import android.util.Log;
import android.util.TypedValue;

import com.google.zxing.BarcodeFormat;
import com.journeyapps.barcodescanner.BarcodeEncoder;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.List;

/**
 * Method buildPdf* private yang ada di fragment Android asli (dikumpulkan & dideduplikasi otomatis
 * dari source). Body method tidak diubah; field fragment (event_buyer, answer) dan
 * requireActivity()/getResources() diganti parameter context. Di app asli method-method ini tidak
 * dipanggil oleh alur aktif (printPdfUSB memakai TemplatePdf), disimpan supaya port lengkap.
 */
public final class FragmentPdfTemplates {
    private FragmentPdfTemplates() {}

    // dari: MakeSureDataFragment, CompletedFragment, Completed2Fragment, TwoManualFragment, ThreeManualFragment, ThreeManual2Fragment
    public static String buildPdf(Context context, int event_buyer, String answer, String filename, String title, String subtitle, String id_ticket, String jobtitle) { // buyer format

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

        String strText="";
        if (event_buyer > 0){
            strText = _subtitle + "\n" + _title + "\n" + _jobtitle;
        }else{
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

        if ((!answer.equals("")) && (!answer.equals("-"))) {

            Resources res = context.getResources();
            Bitmap bitmapGift = BitmapFactory.decodeResource(res, R.drawable.icon_gift);
            Bitmap bGift = (Bitmap.createScaledBitmap(bitmapGift, 35, 35, false));
            canvas.drawBitmap(bGift, mLeft + 10, y_ - ((paint.descent() - paint.ascent())) + 90 - 35, paint);

        }

        try {
            BarcodeEncoder barcodeEncoder = new BarcodeEncoder();
            Bitmap bitmap = barcodeEncoder.encodeBitmap(id_ticket, BarcodeFormat.QR_CODE, 200, 200);
            Bitmap b = (Bitmap.createScaledBitmap(bitmap, 100, 100, false));

            canvas.drawBitmap(b, mRight - 95, (y_ - ((paint.descent() - paint.ascent())) + 3), paint);
        } catch (Exception e) {

        }

        canvas.drawText("QR Code", mRight - 10, y_codeTitle2, paint);

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


        myPdfDocument.close();

        return filepath;
    }

    // dari: MakeSureDataFragment, MakeSureData2Fragment, CompletedFragment, Completed2Fragment, TwoManualFragment, TwoManual2Fragment, ThreeManualFragment, ThreeManual2Fragment
    public static String buildPdf2(Context context, int event_buyer, String answer, String filename, String title, String subtitle, String id_ticket, String jobtitle) { //buildPdf4

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

        int textSize = 20;
        paint.setTextSize(textSize);
        paint.setTypeface(Typeface.defaultFromStyle(Typeface.NORMAL));
        paint.setColor(Color.BLACK);
        paint.setTextAlign(Paint.Align.CENTER);
        paint.getTextBounds(title, 0, title.length(), bounds);

        String strText = title + "\nQR Code";
        String[] str = strText.split("\n");

        Log.e("TAG", "buildPdf2: " + str.length);

        int x_ = (pageWidth) / 2;
        int y_ = (((canvas.getHeight()) - (textSize * str.length) - (80 - textSize)) / 2);
        for (String line : strText.split("\n")) {
            if (line.equals("QR Code")) {
                paint.setTextSize(14);
                paint.setColor(Color.GRAY);
            }
            canvas.drawText(line, x_, y_, paint);
            y_ += paint.descent() - paint.ascent();
        }

        try {
            BarcodeEncoder barcodeEncoder = new BarcodeEncoder();
            Bitmap bitmap = barcodeEncoder.encodeBitmap(id_ticket, BarcodeFormat.QR_CODE, 200, 200);
            Bitmap b = (Bitmap.createScaledBitmap(bitmap, 100, 100, false));
            int centreX = (pageWidth - 100) / 2;
            canvas.drawBitmap(b, centreX, (y_ - ((paint.descent() - paint.ascent())) + 2), paint);
        } catch (Exception e) {

        }

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


        myPdfDocument.close();

        return filepath;
    }

    // dari: MakeSureData2Fragment, TwoManual2Fragment
    public static String buildPdf_MakeSureData2Fragment(Context context, int event_buyer, String answer, String filename, String title, String subtitle, String id_ticket, String jobtitle) { // buyer format

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

        String strText="";
        if (event_buyer > 0){
            strText = _subtitle + "\n" + _title + "\n" + _jobtitle;
        }else{
            strText = _title;
        }

        strText = _subtitle + "\n" + _title + "\n" + _jobtitle;

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

        if ((!answer.equals("")) && (!answer.equals("-"))) {

            Resources res = context.getResources();
            Bitmap bitmapGift = BitmapFactory.decodeResource(res, R.drawable.icon_gift);
            Bitmap bGift = (Bitmap.createScaledBitmap(bitmapGift, 35, 35, false));
            canvas.drawBitmap(bGift, mLeft + 10, y_ - ((paint.descent() - paint.ascent())) + 90 - 35, paint);

        }

        try {
            BarcodeEncoder barcodeEncoder = new BarcodeEncoder();
            Bitmap bitmap = barcodeEncoder.encodeBitmap(id_ticket, BarcodeFormat.QR_CODE, 200, 200);
            Bitmap b = (Bitmap.createScaledBitmap(bitmap, 100, 100, false));

            canvas.drawBitmap(b, mRight - 95, (y_ - ((paint.descent() - paint.ascent())) + 3), paint);
        } catch (Exception e) {

        }

        canvas.drawText("QR Code", mRight - 10, y_codeTitle2, paint);

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


        myPdfDocument.close();

        return filepath;
    }

    // dari: TwoManualFragment, TwoManual2Fragment
    public static Bitmap getBitmapFromString(final String text, final String font, int textSize, final int textColor) {
        String lines[] = text.split("\n");
        textSize = textSize;  //a method in my app that adjusts the font size relative to the screen size
        Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        paint.setTextSize(textSize);
        paint.setColor(textColor);
        paint.setTextAlign(Paint.Align.LEFT);
        
        paint.setTypeface(Typeface.defaultFromStyle(Typeface.NORMAL));

        float baseline = -paint.ascent(); // ascent() is negative
        int width = (int) (paint.measureText(text) + 0.5f); // round
        int height = (int) (baseline + paint.descent() + 0.5f);
        Bitmap image = Bitmap.createBitmap(width, (int) (height * 1.3 * lines.length), Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(image);
        for (int i = 0; i < lines.length; ++i) {
            canvas.drawText(lines[i], 0, baseline + textSize * 1.3f * i, paint);
        }
        return image;
    }

    // dari: TwoManualFragment, TwoManual2Fragment
    public static Bitmap textAsBitmap(String text, float textSize, int textColor, Context mContext) {
        Paint paint = new Paint(ANTI_ALIAS_FLAG);
        int pixel = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, textSize, mContext.getResources().getDisplayMetrics());

        String[] str = text.split("\n");

        paint.setTextSize(pixel);
        paint.setColor(textColor);
        paint.setTextAlign(Paint.Align.LEFT);
        float baseline = -paint.ascent(); // ascent() is negative
        int width = (int) (paint.measureText(text) + 0.0f); // round

        int height = (int) (baseline + paint.descent() + 0.0f);
        Bitmap image = Bitmap.createBitmap((width / str.length) + 10, (height * str.length), Bitmap.Config.ARGB_8888);

        Canvas canvas = new Canvas(image);

        for (int i = 0; i < str.length; i++) {
            float textOffset = (canvas.getWidth() - paint.measureText((str[i]))) / 2;
            canvas.drawText(str[i], textOffset, ((i + 1) * baseline), paint);
        }

        return image;
    }

    // dari: TwoManualFragment, TwoManual2Fragment
    public static String buildPdf_(Context context, int event_buyer, String answer, String filename, String title, String subtitle, String id_ticket, String jobtitle) { //buildPdf4

        Rect bounds = new Rect();
        int pageWidth = 250;
        int pageheight = 180;
        int pathHeight = 2;

        

        String _filename = filename + ".pdf";
        PdfDocument myPdfDocument = new PdfDocument();
        Paint paint = new Paint();
        Paint paint2 = new Paint();
        Path path = new Path();
        PdfDocument.PageInfo myPageInfo = new PdfDocument.PageInfo.Builder(pageWidth, pageheight, 1).create();
        PdfDocument.Page documentPage = myPdfDocument.startPage(myPageInfo);
        Canvas canvas = documentPage.getCanvas();
        int y = 35; // x = 10,
        int x = 10;

        paint.setTextSize(20);
        paint.setTypeface(Typeface.defaultFromStyle(Typeface.NORMAL));
        paint.setColor(Color.BLACK);
        paint.getTextBounds(subtitle, 0, subtitle.length(), bounds);
        x = (canvas.getWidth() / 2) - (bounds.width() / 2);
        canvas.drawText(subtitle, x, y, paint);

        y += 5;

        


        paint.setTextSize(20);
        paint.setTypeface(Typeface.defaultFromStyle(Typeface.NORMAL));
        paint.setColor(Color.BLACK);
        paint.getTextBounds(title, 0, title.length(), bounds);
        x = (canvas.getWidth() / 2) - (bounds.width() / 2);
        y += paint.descent() - paint.ascent();
        canvas.drawText(title, x, y, paint);

        y += 5;

        paint.setTextSize(20);
        paint.setTypeface(Typeface.defaultFromStyle(Typeface.NORMAL));
        paint.setColor(Color.BLACK);
        paint.getTextBounds(jobtitle, 0, jobtitle.length(), bounds);
        x = (canvas.getWidth() / 2) - (bounds.width() / 2);
        y += paint.descent() - paint.ascent();
        canvas.drawText(jobtitle, x, y, paint);

        
        y += 35;

        if ((!answer.equals("")) && (!answer.equals("-"))) {

            Resources res = context.getResources();
            Bitmap bitmap = BitmapFactory.decodeResource(res, R.drawable.icon_gift);
            Bitmap b = (Bitmap.createScaledBitmap(bitmap, 35, 35, false));
            int centreX = (pageWidth - 50) / 2;
            int centreY = (pageheight - 50) / 2;
            canvas.drawBitmap(b, 10, y, paint);

        }

        

        


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


        myPdfDocument.close();

        return filepath;
    }

    // dari: TwoManualFragment, TwoManual2Fragment
    public static String buildPdf2_(Context context, int event_buyer, String answer, String filename, String title, String subtitle, String id_ticket, String jobtitle) { //buildPdf4

        Rect bounds = new Rect();
        int pageWidth = 250;
        int pageheight = 180;
        int pathHeight = 2;

        

        String _filename = filename + ".pdf";
        PdfDocument myPdfDocument = new PdfDocument();
        Paint paint = new Paint();
        Paint paint2 = new Paint();
        Path path = new Path();
        PdfDocument.PageInfo myPageInfo = new PdfDocument.PageInfo.Builder(pageWidth, pageheight, 1).create();
        PdfDocument.Page documentPage = myPdfDocument.startPage(myPageInfo);
        Canvas canvas = documentPage.getCanvas();
        int y = 35; // x = 10,
        int x = 10;

        paint.setTextSize(20);
        paint.setTypeface(Typeface.defaultFromStyle(Typeface.NORMAL));
        paint.setColor(Color.BLACK);
        paint.getTextBounds(title, 0, title.length(), bounds);
        x = (canvas.getWidth() / 2) - (bounds.width() / 2);

        int centreX = (pageWidth - 100) / 2;
        int centreY = (pageheight - 125) / 2;
        canvas.drawText(title, x, centreY, paint);

        centreY = (pageheight - 100) / 2;

        paint.setTextSize(16);
        paint.setTypeface(Typeface.defaultFromStyle(Typeface.NORMAL));
        paint.setColor(Color.GRAY);
        String str_qr = "QR Code";
        paint.getTextBounds(str_qr, 0, str_qr.length(), bounds);
        x = (canvas.getWidth() / 2) - (bounds.width() / 2);
        y += paint.descent() - paint.ascent();
        canvas.drawText(str_qr, centreX, centreY, paint);


        


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


        myPdfDocument.close();

        return filepath;
    }

    // dari: TwoManualFragment, TwoManual2Fragment
    public static String buildPdf2_2(Context context, int event_buyer, String answer, String filename, String title, String subtitle, String id_ticket, String jobtitle) { //buildPdf4

        Rect bounds = new Rect();
        int pageWidth = 250;
        int pageheight = 180;
        int pathHeight = 2;

        

        String _filename = filename + ".pdf";
        PdfDocument myPdfDocument = new PdfDocument();
        Paint paint = new Paint();
        Paint paint2 = new Paint();
        Path path = new Path();
        PdfDocument.PageInfo myPageInfo = new PdfDocument.PageInfo.Builder(pageWidth, pageheight, 1).create();
        PdfDocument.Page documentPage = myPdfDocument.startPage(myPageInfo);
        Canvas canvas = documentPage.getCanvas();
        Canvas canvas_ = documentPage.getCanvas();
        

        int centreX = (pageWidth) / 2;
        int centreY = (pageheight) / 2;

        

        String dd = "islahudin\nkreen indonesia\nmalaysia";
        Bitmap pp = textAsBitmap(dd, 20, Color.BLACK, context);


        

        canvas.drawBitmap(pp, 10, centreY, paint);


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


        myPdfDocument.close();

        return filepath;
    }

    // dari: TwoManualFragment, TwoManual2Fragment
    public static String buildPdf2_mulitlineCenter(Context context, int event_buyer, String answer, String filename, String title, String subtitle, String id_ticket, String jobtitle) { //buildPdf4

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

        int textSize = 20;
        paint.setTextSize(textSize);
        paint.setTypeface(Typeface.defaultFromStyle(Typeface.NORMAL));
        paint.setColor(Color.BLACK);
        paint.setTextAlign(Paint.Align.CENTER);
        paint.getTextBounds(title, 0, title.length(), bounds);

        String strText = "islahudin\nkreen indonesia\nmalaysia";
        String[] str = strText.split("\n");

        Log.e("TAG", "buildPdf2: " + str.length);

        int x_ = (pageWidth) / 2;
        int y_ = (((canvas.getHeight()) - (textSize * str.length)) / 2);
        for (String line : strText.split("\n")) {
            canvas.drawText(line, x_, y_, paint);
            y_ += paint.descent() - paint.ascent();
        }

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


        myPdfDocument.close();

        return filepath;
    }

    // dari: TwoManualFragment, TwoManual2Fragment
    public static String buildPdf2_mulitlineCenterQrcode(Context context, int event_buyer, String answer, String filename, String title, String subtitle, String id_ticket, String jobtitle) { //buildPdf4

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

        int textSize = 20;
        paint.setTextSize(textSize);
        paint.setTypeface(Typeface.defaultFromStyle(Typeface.NORMAL));
        paint.setColor(Color.BLACK);
        paint.setTextAlign(Paint.Align.CENTER);
        paint.getTextBounds(title, 0, title.length(), bounds);

        String strText = "islahudin\nkreen indonesia\nmalaysia";
        String[] str = strText.split("\n");

        Log.e("TAG", "buildPdf2: " + str.length);

        int x_ = (pageWidth) / 2;
        int y_ = (((canvas.getHeight()) - (textSize * str.length) - (80 - textSize)) / 2);
        for (String line : strText.split("\n")) {
            canvas.drawText(line, x_, y_, paint);
            y_ += paint.descent() - paint.ascent();
        }

        int x = (canvas.getWidth() / 2) - (bounds.width() / 2);
        try {
            BarcodeEncoder barcodeEncoder = new BarcodeEncoder();
            Bitmap bitmap = barcodeEncoder.encodeBitmap(id_ticket, BarcodeFormat.QR_CODE, 200, 200);
            Bitmap b = (Bitmap.createScaledBitmap(bitmap, 100, 100, false));
            int centreX = (pageWidth - 100) / 2;
            canvas.drawBitmap(b, centreX, (y_ - textSize), paint);
        } catch (Exception e) {

        }

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


        myPdfDocument.close();

        return filepath;
    }

    // dari: TwoManualFragment, TwoManual2Fragment
    public static String buildPdf_final(Context context, int event_buyer, String answer, String filename, String title, String subtitle, String id_ticket, String jobtitle) { //buildPdf4

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

        int textSize = 20;
        paint.setTextSize(textSize);
        paint.setTypeface(Typeface.defaultFromStyle(Typeface.NORMAL));
        paint.setColor(Color.BLACK);
        paint.setTextAlign(Paint.Align.CENTER);
        paint.getTextBounds(title, 0, title.length(), bounds);

        String strText = "islahudin soft01\nkreen indonesia\nmalaysia";
        String[] str = strText.split("\n");

        Log.e("TAG", "buildPdf2: " + str.length);

        int x_ = (pageWidth) / 2;
        int y_ = (((canvas.getHeight()) - (textSize * str.length) - (80 - textSize)) / 2);
        for (String line : strText.split("\n")) {
            canvas.drawText(line, x_, y_, paint);
            y_ += paint.descent() - paint.ascent();
        }

        float posX = (canvas.getWidth() - bounds.width()) / 2; // center
        float posY = ((canvas.getHeight() - bounds.height()) / 2); // center

        int mRight = canvas.getClipBounds().right;
        int mLeft = canvas.getClipBounds().left;
        int mBottom = canvas.getClipBounds().bottom;
        int mTop = canvas.getClipBounds().top;

        

        float y_codeTitle1 = (y_ - ((paint.descent() - paint.ascent())));
        float y_codeTitle2 = y_;
        int x2 = (canvas.getWidth() / 2) - (bounds.width() / 2);
        paint.setTextSize(14);
        paint.setColor(Color.GRAY);
        paint.setTextAlign(Paint.Align.RIGHT);

        Resources res = context.getResources();
        Bitmap bitmapGift = BitmapFactory.decodeResource(res, R.drawable.icon_gift);
        Bitmap bGift = (Bitmap.createScaledBitmap(bitmapGift, 35, 35, false));
        canvas.drawBitmap(bGift, mLeft + 10, y_ - ((paint.descent() - paint.ascent())) + 90 - 35, paint);

        try {
            BarcodeEncoder barcodeEncoder = new BarcodeEncoder();
            Bitmap bitmap = barcodeEncoder.encodeBitmap(id_ticket, BarcodeFormat.QR_CODE, 200, 200);
            Bitmap b = (Bitmap.createScaledBitmap(bitmap, 100, 100, false));
            int centreX = (pageWidth - 100) / 2;
            canvas.drawBitmap(b, mRight - 95, (y_ - ((paint.descent() - paint.ascent())) + 1), paint);
        } catch (Exception e) {

        }

        canvas.drawText("QR Code", mRight - 10, y_codeTitle2 - 5, paint);

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


        myPdfDocument.close();

        return filepath;
    }

    // dari: TwoManual2Fragment
    public static String buildPdfMfinal(Context context, int event_buyer, String answer, String filename, String id_ticket,List<String> detailValues) { // buyer format

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

        int textSize = 20;// 20
        paint.setTextSize(textSize);
        paint.setTypeface(Typeface.defaultFromStyle(Typeface.NORMAL));
        paint.setColor(Color.BLACK);
        paint.setTextAlign(Paint.Align.CENTER);

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

        if ((!answer.equals("")) && (!answer.equals("-"))) {

            Resources res = context.getResources();
            Bitmap bitmapGift = BitmapFactory.decodeResource(res, R.drawable.icon_gift);
            Bitmap bGift = (Bitmap.createScaledBitmap(bitmapGift, 35, 35, false));
            canvas.drawBitmap(bGift, mLeft + 10, y_ - ((paint.descent() - paint.ascent())) + 90 - 35, paint);

        }

        try {
            BarcodeEncoder barcodeEncoder = new BarcodeEncoder();
            Bitmap bitmap = barcodeEncoder.encodeBitmap(id_ticket, BarcodeFormat.QR_CODE, 200, 200);
            Bitmap b = (Bitmap.createScaledBitmap(bitmap, 100, 100, false));

            canvas.drawBitmap(b, mRight - 95, (y_ - ((paint.descent() - paint.ascent())) + 3), paint);
        } catch (Exception e) {

        }

        canvas.drawText("QR Code", mRight - 10, y_codeTitle2, paint);

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


        myPdfDocument.close();

        return filepath;
    }

}
