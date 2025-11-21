
interface EmailOptions {
    to: string;
    subject: string;
    html: string;
    text?: string;
}

export async function sendEmail({ to, subject, html, text }: EmailOptions): Promise<boolean> {
    // Check for API keys
    const sendgridKey = process.env.SENDGRID_API_KEY;
    const resendKey = process.env.RESEND_API_KEY;
    const fromEmail = process.env.EMAIL_FROM || 'noreply@hobbi.app';
    const fromName = process.env.EMAIL_FROM_NAME || 'Hobbyist Partner Portal';

    if (resendKey) {
        return sendViaResend(resendKey, { to, subject, html, text, from: `${fromName} <${fromEmail}>` });
    }

    if (sendgridKey) {
        return sendViaSendGrid(sendgridKey, { to, subject, html, text, from: { email: fromEmail, name: fromName } });
    }

    // Fallback for development
    if (process.env.NODE_ENV === 'development') {
        console.log('📧 [DEV] Email sent:', { to, subject, html });
        return true;
    }

    console.error('❌ No email provider configured (SENDGRID_API_KEY or RESEND_API_KEY missing)');
    return false;
}

async function sendViaResend(apiKey: string, data: any) {
    try {
        const response = await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                from: data.from,
                to: [data.to],
                subject: data.subject,
                html: data.html,
                text: data.text,
            }),
        });

        if (!response.ok) {
            const error = await response.json();
            console.error('Resend API error:', error);
            return false;
        }

        return true;
    } catch (error) {
        console.error('Error sending email via Resend:', error);
        return false;
    }
}

async function sendViaSendGrid(apiKey: string, data: any) {
    try {
        const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                personalizations: [{ to: [{ email: data.to }] }],
                from: data.from,
                subject: data.subject,
                content: [
                    { type: 'text/plain', value: data.text || data.html.replace(/<[^>]*>?/gm, '') },
                    { type: 'text/html', value: data.html },
                ],
            }),
        });

        if (!response.ok) {
            const error = await response.json();
            console.error('SendGrid API error:', error);
            return false;
        }

        return true;
    } catch (error) {
        console.error('Error sending email via SendGrid:', error);
        return false;
    }
}
