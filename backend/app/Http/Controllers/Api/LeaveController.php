<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

class LeaveController extends Controller
{
    public function index()
    {
        return response()->json([
            'status' => 'success',
            'module' => 'LeaveController',
            'data' => [],
        ]);
    }
}