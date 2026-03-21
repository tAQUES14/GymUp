<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;

class PasswordResetController extends Controller
{
    /**
     * Envia o link de recuperação para o e-mail informado.
     *
     * Sempre retorna 200 para não revelar se o e-mail existe.
     */
    public function forgotPassword(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        // Personaliza a URL do link de reset para apontar ao frontend.
        ResetPassword::createUrlUsing(function (User $user, string $token): string {
            $base = rtrim(config('app.frontend_url', 'https://gymup.app'), '/');

            return $base . '/reset-password'
                . '?token=' . $token
                . '&email=' . urlencode($user->getEmailForPasswordReset());
        });

        // Dispara o envio (ignora o status para não vazar informação).
        Password::sendResetLink($request->only('email'));

        return response()->json([
            'message' => 'Se o e-mail existir, enviaremos um link de recuperação em breve.',
        ]);
    }

    /**
     * Redefine a senha usando o token recebido por e-mail.
     */
    public function resetPassword(Request $request): JsonResponse
    {
        $request->validate([
            'token'                 => 'required',
            'email'                 => 'required|email',
            'password'              => 'required|min:6|confirmed',
            'password_confirmation' => 'required',
        ]);

        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function (User $user, string $password): void {
                $user->forceFill([
                    'password' => Hash::make($password),
                ])->save();

                // Invalida todas as sessões anteriores por segurança.
                $user->tokens()->delete();
            }
        );

        if ($status !== Password::PASSWORD_RESET) {
            return response()->json([
                'message' => 'Token inválido ou expirado. Solicite um novo link.',
            ], 422);
        }

        return response()->json([
            'message' => 'Senha redefinida com sucesso. Faça login com a nova senha.',
        ]);
    }
}
