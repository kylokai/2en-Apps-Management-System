<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\StaffController;
use App\Http\Controllers\Api\LeaveController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\ClaimController;

Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'database' => DB::connection()->getDatabaseName(),
        'total_employees' => DB::table('employees')->count(),
    ]);
});

Route::post('/login', [AuthController::class, 'login']);

Route::prefix('staff')->group(function () {
    Route::get('/', [StaffController::class, 'index']);
    Route::post('/', [StaffController::class, 'store']);
    Route::get('/{id}', [StaffController::class, 'show']);
    Route::patch('/{id}', [StaffController::class, 'update']);
});

Route::prefix('leaves')->group(function () {
    Route::get('/', [LeaveController::class, 'index']);
});

Route::prefix('attendances')->group(function () {
    Route::get('/', [AttendanceController::class, 'index']);
});

Route::prefix('claims')->group(function () {
    Route::get('/', [ClaimController::class, 'index']);
});