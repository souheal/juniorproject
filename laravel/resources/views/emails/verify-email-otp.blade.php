<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verify Your Email</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background-color: #ffffff;
            border-radius: 16px;
            padding: 40px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .logo {
            font-size: 28px;
            font-weight: bold;
            color: #6A62FF;
        }
        h1 {
            color: #1F1F1F;
            font-size: 24px;
            margin-bottom: 20px;
            text-align: center;
        }
        .otp-container {
            background: linear-gradient(135deg, #6A62FF 0%, #8B85FF 100%);
            border-radius: 12px;
            padding: 30px;
            text-align: center;
            margin: 30px 0;
        }
        .otp-label {
            color: rgba(255, 255, 255, 0.9);
            font-size: 14px;
            margin-bottom: 10px;
        }
        .otp-code {
            font-size: 42px;
            font-weight: bold;
            color: #ffffff;
            letter-spacing: 8px;
            font-family: 'Courier New', monospace;
        }
        .message {
            color: #666;
            font-size: 16px;
            margin-bottom: 20px;
            text-align: center;
        }
        .warning {
            background-color: #FFF3CD;
            border: 1px solid #FFEEBA;
            border-radius: 8px;
            padding: 15px;
            margin-top: 20px;
            font-size: 14px;
            color: #856404;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            color: #999;
            font-size: 12px;
        }
        .highlight {
            color: #6A62FF;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">Eventy</div>
        </div>

        <h1>Verify Your Email</h1>

        <p class="message">
            Hello <span class="highlight">{{ $user->name }}</span>,<br>
            Welcome to Eventy! Use the code below to verify your email address.
        </p>

        <div class="otp-container">
            <div class="otp-label">Your Verification Code</div>
            <div class="otp-code">{{ $otpCode }}</div>
        </div>

        <p class="message">
            Enter this code in the app to complete your registration.
        </p>

        <div class="warning">
            <strong>Important:</strong> This code will expire in <strong>10 minutes</strong>.
            If you didn't create an account with Eventy, please ignore this email.
        </div>

        <div class="footer">
            <p>&copy; {{ date('Y') }} Eventy. All rights reserved.</p>
            <p>This is an automated message, please do not reply.</p>
        </div>
    </div>
</body>
</html>
