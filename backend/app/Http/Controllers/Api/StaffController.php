<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StaffController extends Controller
{
    public function index()
    {
        $staff = DB::table('v_staff_directory')->orderBy('id')->get();

        return response()->json([
            'status' => 'success',
            'data' => $staff,
        ]);
    }

    public function show($id)
    {
        $emp = DB::table('employees')->where('id', $id)->whereNull('deleted_at')->first();
        if (!$emp) {
            return response()->json(['message' => 'Staf tidak ditemui'], 404);
        }

        $dir = DB::table('v_staff_directory')->where('id', $id)->first();
        $role = DB::table('user_roles')
            ->join('roles', 'roles.id', '=', 'user_roles.role_id')
            ->where('user_roles.user_id', $emp->user_id)
            ->select('roles.code', 'roles.name')
            ->first();

        $docs = DB::table('employee_documents')->where('employee_id', $id)->get();
        $history = DB::table('employment_history')->where('employee_id', $id)->orderByDesc('effective_date')->get();
        $audits = DB::table('audit_logs')->where('employee_id', $id)->orderByDesc('created_at')->limit(10)->get();

        return response()->json([
            'status' => 'success',
            'data' => [
                'profile' => $emp,
                'directory' => $dir,
                'role' => $role,
                'documents' => $docs,
                'history' => $history,
                'audits' => $audits,
            ],
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'full_name' => 'required|string|max:150',
            'email' => 'required|email|unique:employees,email',
            'position_title' => 'required|string',
            'department_name' => 'required|string',
        ]);

        $parts = preg_split('/\s+/', trim($request->full_name));
        $firstName = $parts[0];
        $lastName = count($parts) > 1 ? implode(' ', array_slice($parts, 1)) : '-';
        $count = DB::table('employees')->count() + 100;
        $empNo = 'EMP-2026-' . str_pad((string)$count, 4, '0', STR_PAD_LEFT);

        $deptId = DB::table('departments')->where('name', 'like', '%' . $request->department_name . '%')->value('id') ?? 1;
        $posId = DB::table('positions')->where('title', 'like', '%' . $request->position_title . '%')->value('id') ?? 2;

        $id = DB::table('employees')->insertGetId([
            'employee_no' => $empNo,
            'company_id' => 1,
            'branch_id' => 1,
            'department_id' => $deptId,
            'position_id' => $posId,
            'reports_to_employee_id' => 3,
            'first_name' => $firstName,
            'last_name' => $lastName,
            'full_name' => trim($request->full_name),
            'email' => trim($request->email),
            'phone' => $request->phone ?? '-',
            'employment_type' => 'PERMANENT',
            'employment_status' => 'Active',
            'hire_date' => now()->toDateString(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('audit_logs')->insert([
            'action' => 'CREATE',
            'table_name' => 'employees',
            'record_id' => $id,
            'employee_id' => $id,
            'after_json' => json_encode(['employee_no' => $empNo, 'full_name' => $request->full_name]),
            'created_at' => now(),
        ]);

        return response()->json([
            'status' => 'success',
            'message' => "{$request->full_name} berjaya ditambah sebagai {$empNo}",
            'id' => $id,
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $emp = DB::table('employees')->where('id', $id)->first();
        if (!$emp) {
            return response()->json(['message' => 'Staf tidak ditemui'], 404);
        }

        $allowed = $request->only(['phone', 'email', 'address_1', 'city', 'postcode', 'emergency_contact_name', 'emergency_contact_phone']);
        $allowed['updated_at'] = now();

        DB::table('employees')->where('id', $id)->update($allowed);

        DB::table('audit_logs')->insert([
            'action' => 'UPDATE',
            'table_name' => 'employees',
            'record_id' => $id,
            'employee_id' => $id,
            'after_json' => json_encode($allowed),
            'created_at' => now(),
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Profil dikemas kini dan direkodkan dalam audit log.',
        ]);
    }
}