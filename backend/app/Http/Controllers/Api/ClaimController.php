<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

class ClaimController extends Controller
{
    public function index()
    {
        return response()->json([
            'status' => 'success',
            'module' => 'ClaimController',
            'data' => [],
        ]);
    }
}