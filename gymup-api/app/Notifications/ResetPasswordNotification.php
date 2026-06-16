<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class ResetPasswordNotification extends Notification
{
    use Queueable;

    public function __construct(private readonly string $url) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('Redefina sua senha do GymUp')
            ->greeting('Vamos recuperar seu acesso')
            ->line('Recebemos uma solicitacao para redefinir a senha da sua conta.')
            ->action('Criar nova senha', $this->url)
            ->line('Se voce nao solicitou essa alteracao, pode ignorar este email com seguranca.');
    }
}
