<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

class AttendanceController extends Controller
{
    public function index()
    {
        return response()->json([
            'status' => 'success',
            'module' => 'AttendanceController',
            'data' => [],
        ]);
    }
}