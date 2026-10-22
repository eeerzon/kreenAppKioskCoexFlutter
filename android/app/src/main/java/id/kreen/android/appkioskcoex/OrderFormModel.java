package id.kreen.android.appkioskcoex;

import java.io.Serializable;

/** data/remote/response/OrderFormModel.java (diisi dari Dart lewat MethodChannel). */
public class OrderFormModel implements Serializable {
    private String id;
    private String question;
    private String answer;
    private String idQuestion;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getQuestion() { return question; }
    public void setQuestion(String question) { this.question = question; }

    public String getAnswer() { return answer; }
    public void setAnswer(String answer) { this.answer = answer; }

    public String getIdQuestion() { return idQuestion; }
    public void setIdQuestion(String idQuestion) { this.idQuestion = idQuestion; }
}
