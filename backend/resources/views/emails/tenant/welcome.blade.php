<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Welcome to the Platform</title>
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
    <h1 style="color: #2d6a4f;">Welcome, {{ $tenant->name }}!</h1>

    <p>Your food ordering store has been successfully provisioned. Here are your login credentials:</p>

    <table style="border-collapse: collapse; width: 100%; margin: 20px 0;">
        <tr>
            <td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">Store URL</td>
            <td style="padding: 8px; border: 1px solid #ddd;">https://{{ $domain }}</td>
        </tr>
        <tr>
            <td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">Admin Email</td>
            <td style="padding: 8px; border: 1px solid #ddd;">{{ $adminEmail }}</td>
        </tr>
        <tr>
            <td style="padding: 8px; border: 1px solid #ddd; font-weight: bold;">Temporary Password</td>
            <td style="padding: 8px; border: 1px solid #ddd;">{{ $adminPassword }}</td>
        </tr>
    </table>

    <p style="color: #e63946;"><strong>Please change your password after your first login.</strong></p>

    <p>If you have any questions, please contact our support team.</p>

    <p>Best regards,<br>The Platform Team</p>
</body>
</html>
