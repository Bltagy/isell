<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\User;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification as FcmNotification;
use Kreait\Laravel\Firebase\Facades\Firebase;

class NotificationService
{
    /**
     * Send notification to a single user.
     */
    public function sendToUser(
        int $userId,
        string $titleEn,
        string $titleAr,
        string $bodyEn,
        string $bodyAr,
        string $type = 'general',
        array $data = [],
        string $sentVia = 'both'
    ): void {
        $user = User::find($userId);
        if (!$user) return;

        // Store in DB
        Notification::create([
            'user_id'   => $userId,
            'title_en'  => $titleEn,
            'title_ar'  => $titleAr,
            'body_en'   => $bodyEn,
            'body_ar'   => $bodyAr,
            'type'      => $type,
            'data_json' => $data ?: null,
            'sent_via'  => $sentVia,
        ]);

        // Send FCM if user has token
        if (in_array($sentVia, ['fcm', 'both']) && $user->fcm_token) {
            $this->sendFcm($user->fcm_token, $titleEn, $bodyEn, $data);
        }
    }

    /**
     * Send to multiple users.
     */
    public function sendToMultiple(
        array $userIds,
        string $titleEn,
        string $titleAr,
        string $bodyEn,
        string $bodyAr,
        string $type = 'general',
        array $data = []
    ): void {
        foreach ($userIds as $userId) {
            $this->sendToUser($userId, $titleEn, $titleAr, $bodyEn, $bodyAr, $type, $data);
        }
    }

    /**
     * Broadcast to all active users.
     */
    public function broadcastToAll(
        string $titleEn,
        string $titleAr,
        string $bodyEn,
        string $bodyAr,
        string $type = 'general',
        array $data = []
    ): void {
        User::active()->chunk(100, function ($users) use ($titleEn, $titleAr, $bodyEn, $bodyAr, $type, $data) {
            foreach ($users as $user) {
                $this->sendToUser($user->id, $titleEn, $titleAr, $bodyEn, $bodyAr, $type, $data);
            }
        });
    }

    /**
     * Send FCM push notification.
     */
    private function sendFcm(string $token, string $title, string $body, array $data = []): void
    {
        try {
            $messaging = Firebase::messaging();

            $message = CloudMessage::withTarget('token', $token)
                ->withNotification(FcmNotification::create($title, $body))
                ->withData(array_map('strval', $data));

            $messaging->send($message);
        } catch (\Throwable $e) {
            Log::error('FCM send failed', ['error' => $e->getMessage(), 'token' => $token]);
        }
    }
}
