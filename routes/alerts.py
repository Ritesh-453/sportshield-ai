import smtplib
import os
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from datetime import datetime

def send_violation_alert(asset_name, similarity, found_url=None):
    try:
        sender = os.getenv('MAIL_EMAIL')
        password = os.getenv('MAIL_PASSWORD')
        receiver = os.getenv('ALERT_EMAIL')

        if not all([sender, password, receiver]):
            print("Email credentials not configured")
            return False

        msg = MIMEMultipart('alternative')
        msg['Subject'] = f'🚨 SportShield Alert: Violation Detected — {asset_name}'
        msg['From'] = sender
        msg['To'] = receiver

        html = f"""
        <html>
        <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <div style="background: #4f46e5; padding: 24px; border-radius: 12px 12px 0 0;">
                <h1 style="color: white; margin: 0; font-size: 24px;">
                    🛡️ SportShield AI
                </h1>
                <p style="color: #c7d2fe; margin: 4px 0 0;">
                    Digital Asset Protection Alert
                </p>
            </div>

            <div style="background: #fff1f2; border: 1px solid #fecdd3;
                        padding: 20px; margin: 0;">
                <h2 style="color: #e11d48; margin: 0 0 8px;">
                    ⚠️ Violation Detected
                </h2>
                <p style="color: #475569; margin: 0;">
                    An unauthorized use of your protected asset has been detected.
                </p>
            </div>

            <div style="background: white; border: 1px solid #e2e8f0;
                        padding: 24px; border-radius: 0 0 12px 12px;">
                <table style="width: 100%; border-collapse: collapse;">
                    <tr style="border-bottom: 1px solid #f1f5f9;">
                        <td style="padding: 12px 0; color: #64748b;
                                   font-weight: 600; width: 40%;">Asset Name</td>
                        <td style="padding: 12px 0; color: #0f172a;
                                   font-weight: 700;">{asset_name}</td>
                    </tr>
                    <tr style="border-bottom: 1px solid #f1f5f9;">
                        <td style="padding: 12px 0; color: #64748b;
                                   font-weight: 600;">Similarity Score</td>
                        <td style="padding: 12px 0;">
                            <span style="background: #fff1f2; color: #e11d48;
                                         padding: 4px 12px; border-radius: 999px;
                                         font-weight: 700;">{similarity}% Match</span>
                        </td>
                    </tr>
                    <tr style="border-bottom: 1px solid #f1f5f9;">
                        <td style="padding: 12px 0; color: #64748b;
                                   font-weight: 600;">Risk Level</td>
                        <td style="padding: 12px 0;">
                            <span style="background: #e11d48; color: white;
                                         padding: 4px 12px; border-radius: 999px;
                                         font-weight: 700;">
                                {"CRITICAL" if similarity >= 90 else "HIGH"}
                            </span>
                        </td>
                    </tr>
                    <tr style="border-bottom: 1px solid #f1f5f9;">
                        <td style="padding: 12px 0; color: #64748b;
                                   font-weight: 600;">Detected At</td>
                        <td style="padding: 12px 0; color: #0f172a;">
                            {datetime.now().strftime("%d %b %Y, %H:%M")}
                        </td>
                    </tr>
                    {"<tr><td style='padding: 12px 0; color: #64748b; font-weight: 600;'>Found At</td><td style='padding: 12px 0;'><a href='" + found_url + "' style='color: #4f46e5;'>" + found_url[:50] + "...</a></td></tr>" if found_url else ""}
                </table>

                <div style="margin-top: 24px; padding: 16px; background: #f8fafc;
                            border-radius: 8px; border-left: 4px solid #4f46e5;">
                    <p style="margin: 0; color: #475569; font-size: 14px;">
                        <strong>Recommended Action:</strong> Review this violation
                        in your SportShield dashboard and consider sending a
                        takedown notice to the infringing party.
                    </p>
                </div>

                <div style="margin-top: 20px; text-align: center;">
                    <a href="http://127.0.0.1:5000/violations"
                       style="background: #4f46e5; color: white; padding: 12px 24px;
                              border-radius: 8px; text-decoration: none;
                              font-weight: 600; display: inline-block;">
                        View in Dashboard →
                    </a>
                </div>

                <p style="margin-top: 24px; color: #94a3b8; font-size: 12px;
                          text-align: center;">
                    SportShield AI — Protecting the integrity of digital sports media
                </p>
            </div>
        </body>
        </html>
        """

        msg.attach(MIMEText(html, 'html'))

        with smtplib.SMTP_SSL('smtp.gmail.com', 465) as server:
            server.login(sender, password)
            server.sendmail(sender, receiver, msg.as_string())

        print(f"Alert email sent for {asset_name}")
        return True

    except Exception as e:
        print(f"Email alert error: {e}")
        return False