<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\URL;

class VerifyEmailNotification extends Notification
{
    use Queueable;

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $url = URL::temporarySignedRoute(
            'verification.verify',
            now()->addHours(24),
            [
                'id' => $notifiable->getKey(),
                'hash' => sha1((string) $notifiable->email),
            ]
        );

        return (new MailMessage)
            ->subject('Confirme seu email no GymUp')
            ->greeting('Bem-vindo ao GymUp!')
            ->line('Confirme seu email para liberar o acesso a sua conta.')
            ->action('Confirmar email', $url)
            ->line('Este link expira em 24 horas. Se voce nao criou uma conta, pode ignorar este email.');
    }
}
