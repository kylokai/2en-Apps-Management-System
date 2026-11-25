<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = DB::table('user_accounts')
            ->whereRaw('LOWER(email) = ?', [strtolower(trim($request->email))])
            ->first();

        if (!$user || !Hash::check($request->password, $user->password_hash)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Emel atau kata laluan tidak sah. Guna akaun demo (kata laluan: demo1234).',
            ], 401);
        }

        $role = DB::table('user_roles')
            ->join('roles', 'roles.id', '=', 'user_roles.role_id')
            ->where('user_roles.user_id', $user->id)
            ->select('roles.code', 'roles.name')
            ->first();

        $employee = DB::table('v_staff_directory')
            ->where('id', DB::table('employees')->where('user_id', $user->id)->value('id'))
            ->first();

        DB::table('user_accounts')->where('id', $user->id)->update(['last_login_at' => now()]);

        return response()->json([
            'status' => 'success',
            'user' => [
                'account_id' => $user->id,
                'email' => $user->email,
                'role_code' => $role->code ?? 'STAFF',
                'role_name' => $role->name ?? 'Staff',
                'employee' => $employee,
            ],
        ]);
    }
}