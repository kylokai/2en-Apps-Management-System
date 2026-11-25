<script setup>
import { ref, computed, onMounted } from 'vue';
import api from './services/api';
import StaffView from './modules/staff/StaffView.vue';
import LeaveView from './modules/leave/LeaveView.vue';
import AttendanceView from './modules/attendance/AttendanceView.vue';
import ClaimView from './modules/claim/ClaimView.vue';

const currentUser = ref(null);
const loginEmail = ref('aina.rahman@2enapps.my');
const loginPass = ref('demo1234');
const loginError = ref('');

const activeView = ref('dashboard');
const sidebarMin = ref(false);
const darkMode = ref(false);
const health = ref(null);
const staffList = ref([]);
const toastMsg = ref('');

const demoAccounts = [
  { label: 'Owner / Boss', email: 'faisal@2enapps.my' },
  { label: 'HR Admin', email: 'aminah.osman@2enapps.my' },
  { label: 'Manager', email: 'wei.jian@2enapps.my' },
  { label: 'Staff', email: 'aina.rahman@2enapps.my' },
  { label: 'Intern', email: 'arif.kamal@2enapps.my' },
];

const roleCode = computed(() => currentUser.value?.role_code || 'STAFF');
const isBoss = computed(() => roleCode.value === 'OWNER_BOSS');
const isHR = computed(() => roleCode.value === 'HR_ADMIN');
const isManager = computed(() => roleCode.value === 'MANAGER');
const canSeeDirectory = computed(() => isBoss.value || isHR.value || isManager.value);

function notify(msg) {
  toastMsg.value = msg;
  setTimeout(() => { toastMsg.value = ''; }, 3200);
}

function fillDemo(email) {
  loginEmail.value = email;
  loginPass.value = 'demo1234';
  loginError.value = '';
}

async function signIn() {
  loginError.value = '';
  try {
    const res = await api.post('/login', { email: loginEmail.value, password: loginPass.value });
    currentUser.value = res.data.user;
    activeView.value = 'dashboard';
    await loadSystemData();
    notify(`Selamat datang, ${currentUser.value.employee?.full_name || currentUser.value.email}!`);
  } catch (err) {
    loginError.value = err.response?.data?.message || 'Gagal log masuk.';
  }
}

function signOut() {
  currentUser.value = null;
}

function toggleDark() {
  darkMode.value = !darkMode.value;
  document.body.classList.toggle('dark', darkMode.value);
}

async function loadSystemData() {
  const [hRes, sRes] = await Promise.all([api.get('/health'), api.get('/staff')]);
  health.value = hRes.data;
  staffList.value = sRes.data.data || [];
}

onMounted(loadSystemData);
</script>

<template>
  <!-- SKRIN 1: LOG MASUK EMEL (REKA BENTUK ZIYAD) -->
  <div v-if="!currentUser" style="display:flex;min-height:100vh">
    <div style="width:44%;background:linear-gradient(155deg,#12265E,#173A8A 55%,#2456C7);color:#fff;padding:48px;display:flex;flex-direction:column;justify-content:space-between">
      <div style="display:flex;align-items:center;gap:12px">
        <img src="/logo.png" alt="Logo" style="width:42px;height:42px;border-radius:10px;background:#fff;padding:2px" onerror="this.style.display='none'" />
        <div>
          <div style="font-size:18px;font-weight:800">2en Apps Sdn. Bhd.</div>
          <div style="font-size:10px;letter-spacing:1.4px;color:#B9C9F0">HUMAN RESOURCE MANAGEMENT SYSTEM</div>
        </div>
      </div>
      <div>
        <h1 style="font-size:36px;line-height:1.15;margin-bottom:14px">People, managed with confidence.</h1>
        <p style="color:#C9D6F5">Satu ruang kerja bersepadu untuk profil staf, kehadiran, cuti dan tuntutan — bersambung terus ke Laravel &amp; MySQL.</p>
      </div>
      <div style="font-size:11px;color:#9FB4E8">© 2026 2en Apps Sdn. Bhd.</div>
    </div>

    <div style="flex:1;display:grid;place-items:center;padding:32px">
      <div style="width:100%;max-width:420px">
        <div style="font-size:11px;font-weight:800;color:var(--royal-600);letter-spacing:1.2px">SECURE STAFF ACCESS</div>
        <h2 style="margin:6px 0">Welcome back</h2>
        <p style="color:var(--silver-500);font-size:13px;margin-bottom:20px">Log masuk menggunakan emel kerja. Peranan anda dikesan automatik daripada pangkalan data.</p>

        <div style="margin-bottom:12px">
          <label style="font-size:11px;font-weight:800;color:var(--silver-500)">WORK EMAIL</label>
          <input class="input" v-model="loginEmail" type="email" />
        </div>
        <div style="margin-bottom:14px">
          <label style="font-size:11px;font-weight:800;color:var(--silver-500)">PASSWORD</label>
          <input class="input" v-model="loginPass" type="password" />
        </div>
        <p v-if="loginError" style="color:var(--danger);font-size:12px">{{ loginError }}</p>
        <button class="btn btn-primary" style="width:100%;justify-content:center;padding:12px" @click="signIn">
          Sign in to workspace →
        </button>

        <div style="margin-top:18px;padding:12px;background:var(--royal-50);border:1px solid #D6E4FF;border-radius:10px;font-size:12px">
          <b>Akaun Demo (kata laluan: <code>demo1234</code>):</b>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;margin-top:8px">
            <button v-for="acc in demoAccounts" :key="acc.email" class="btn btn-sm" style="flex-direction:column;align-items:flex-start" @click="fillDemo(acc.email)">
              <b>{{ acc.label }}</b>
              <small style="font-weight:400;color:var(--silver-500)">{{ acc.email }}</small>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- SKRIN 2: RUANG KERJA UTAMA (SIDEBAR ROYAL BLUE + 4 MODUL) -->
  <div v-else style="display:flex;min-height:100vh">
    <aside :style="{ width: sidebarMin ? '72px' : '250px' }" style="background:var(--sidebar-bg);color:#fff;display:flex;flex-direction:column;transition:width .2s;flex-shrink:0">
      <div style="height:70px;display:flex;align-items:center;justify-content:space-between;padding:0 16px;border-bottom:1px solid rgba(255,255,255,.14)">
        <div v-if="!sidebarMin" style="display:flex;align-items:center;gap:10px">
          <img src="/logo.png" alt="Logo" style="width:32px;height:32px;border-radius:8px;background:#fff" onerror="this.style.display='none'" />
          <div>
            <div style="font-size:13px;font-weight:800">2en Apps Sdn. Bhd.</div>
            <div style="font-size:9px;opacity:.75">HR MANAGEMENT</div>
          </div>
        </div>
        <button @click="sidebarMin = !sidebarMin" style="background:rgba(255,255,255,.14);border:none;color:#fff;padding:6px 9px;border-radius:8px">☰</button>
      </div>

      <nav style="flex:1;padding:14px 10px;display:flex;flex-direction:column;gap:4px">
        <button class="nav-btn" :class="{ active: activeView === 'dashboard' }" @click="activeView = 'dashboard'">▦ <span v-if="!sidebarMin">Dashboard</span></button>
        <button class="nav-btn" :class="{ active: activeView === 'attendance' }" @click="activeView = 'attendance'">◷ <span v-if="!sidebarMin">{{ isBoss ? 'Staff Attendance' : 'Attendance' }}</span></button>
        <button class="nav-btn" :class="{ active: activeView === 'leave' }" @click="activeView = 'leave'">▤ <span v-if="!sidebarMin">{{ isBoss ? 'Leave Requests' : 'Leave Application' }}</span></button>
        <button class="nav-btn" :class="{ active: activeView === 'claim' }" @click="activeView = 'claim'">▧ <span v-if="!sidebarMin">Claim</span></button>
        <button v-if="canSeeDirectory" class="nav-btn" :class="{ active: activeView === 'directory' }" @click="activeView = 'directory'">☰ <span v-if="!sidebarMin">{{ isManager ? 'Team Directory' : 'Staff Directory' }}</span></button>
        <button class="nav-btn" :class="{ active: activeView === 'profile' }" @click="activeView = 'profile'">◉ <span v-if="!sidebarMin">Staff Profile</span></button>
      </nav>

      <div style="padding:14px;border-top:1px solid rgba(255,255,255,.14)">
        <div v-if="!sidebarMin" style="margin-bottom:8px;font-size:12px">
          <b>{{ currentUser.employee?.full_name }}</b><br />
          <small style="opacity:.75">{{ currentUser.role_name }}</small>
        </div>
        <button @click="signOut" style="width:100%;background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.25);color:#fff;padding:7px;border-radius:8px;font-weight:700">
          {{ sidebarMin ? '⎋' : 'Sign out' }}
        </button>
      </div>
    </aside>

    <div style="flex:1;display:flex;flex-direction:column;min-width:0">
      <header style="height:70px;background:var(--white);border-bottom:1px solid var(--silver-200);display:flex;align-items:center;justify-content:space-between;padding:0 24px">
        <div style="font-weight:800;font-size:15px">2en Apps HR Workspace</div>
        <div style="display:flex;align-items:center;gap:10px">
          <span v-if="health" class="pill green">● API &amp; DB ({{ health.database }} · {{ health.total_employees }} staf)</span>
          <button class="btn btn-sm" @click="toggleDark">{{ darkMode ? '☀ Light' : '☾ Dark' }}</button>
          <button @click="activeView = 'profile'" style="background:#1E4BB8;color:#fff;border:none;padding:7px 14px;border-radius:20px;font-weight:800;font-size:12.5px">
            {{ currentUser.employee?.full_name }}
          </button>
        </div>
      </header>

      <main style="padding:24px;max-width:1280px;width:100%;margin:0 auto">
        <div v-if="activeView === 'dashboard'">
          <div style="background:linear-gradient(115deg,#12265E,#1E4BB8 60%,#3B73E8);color:#fff;padding:24px;border-radius:16px;margin-bottom:18px">
            <h2 style="margin:0 0 6px">Selamat kembali, {{ currentUser.employee?.full_name }} 👋</h2>
            <p style="margin:0;color:#CAD9F7">Peranan: {{ currentUser.role_name }} ({{ currentUser.employee?.employee_no }})</p>
          </div>
          <div class="card">
            <h3 style="margin-top:0">Akses Pantas Modul Pasukan</h3>
            <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:12px">
              <button class="btn" style="justify-content:center;padding:18px" @click="activeView = 'profile'">1. Staff Profile</button>
              <button class="btn" style="justify-content:center;padding:18px" @click="activeView = 'leave'">2. Leave</button>
              <button class="btn" style="justify-content:center;padding:18px" @click="activeView = 'attendance'">3. Attendance</button>
              <button class="btn" style="justify-content:center;padding:18px" @click="activeView = 'claim'">4. Claim</button>
            </div>
          </div>
        </div>

        <StaffView
          v-else-if="activeView === 'profile' || activeView === 'directory'"
          :current-user="currentUser"
          :staff-list="staffList"
          :initial-mode="activeView"
          @refresh-staff="loadSystemData"
          @notify="notify"
        />
        <LeaveView v-else-if="activeView === 'leave'" />
        <AttendanceView v-else-if="activeView === 'attendance'" />
        <ClaimView v-else-if="activeView === 'claim'" />
      </main>
    </div>
  </div>

  <div v-if="toastMsg" style="position:fixed;bottom:20px;right:20px;background:#12265E;color:#fff;padding:12px 18px;border-radius:10px;font-size:13px;z-index:99">
    {{ toastMsg }}
  </div>
</template>

<style scoped>
.nav-btn {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
  background: transparent;
  border: none;
  color: rgba(255, 255, 255, 0.85);
  padding: 10px 12px;
  border-radius: 9px;
  font-size: 13px;
  font-weight: 700;
  text-align: left;
}
.nav-btn:hover, .nav-btn.active {
  background: rgba(255, 255, 255, 0.18);
  color: #fff;
}
</style>