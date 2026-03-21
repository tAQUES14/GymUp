<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Audit trail for admin actions.
 *
 * Every write action performed by an admin (approve, reject, adjust points, etc.)
 * should produce a record here. This enables:
 *  - Accountability ("who did what and when")
 *  - Dispute resolution ("the admin rejected it at 14:32")
 *  - Academic evaluation ("the system has admin action traceability")
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('admin_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('admin_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('gym_id')->constrained()->onDelete('cascade');
            $table->string('action');           // e.g. approve_redemption, reject_redemption
            $table->string('target_type');      // e.g. redemption
            $table->unsignedBigInteger('target_id');
            $table->text('description');        // human-readable summary
            $table->timestamps();

            $table->index(['admin_id', 'created_at']);
            $table->index(['gym_id',   'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('admin_logs');
    }
};
