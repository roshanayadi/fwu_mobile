<?php
session_start();

// --- Configuration Setup (Must match api.php) ---
$db_host = "127.0.0.1";
$db_name = "koreakh1_fwuapi"; // replace with your DB name
$db_user = "koreakh1_fwu";         // replace with your DB user
$db_pass = "budhalokesh1234";

// Simple Admin Authentication Details
$admin_user = "lokeshbudha";
$admin_pass = "budha123"; // Please change this to a secure password!

// Handle Login
if (isset($_POST['login'])) {
    if ($_POST['username'] === $admin_user && $_POST['password'] === $admin_pass) {
        $_SESSION['loggedin'] = true;
    } else {
        $login_error = "Invalid username or password!";
    }
}

// Handle Logout
if (isset($_GET['logout'])) {
    session_destroy();
    header("Location: dashboard.php");
    exit();
}

// If not logged in, show login form
if (!isset($_SESSION['loggedin']) || $_SESSION['loggedin'] !== true) {
    ?>
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>FWU Portal - Secure Login</title>
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
        <style>
            :root {
                --primary: #4F46E5;
                --primary-hover: #4338CA;
                --bg: #F3F4F6;
                --surface: #FFFFFF;
                --text-main: #111827;
                --text-muted: #6B7280;
                --danger: #EF4444;
            }
            body {
                font-family: 'Inter', sans-serif;
                background: linear-gradient(135deg, #fdfbfb 0%, #ebedee 100%);
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
            }
            .login-box {
                background: var(--surface);
                padding: 40px;
                border-radius: 16px;
                box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
                width: 320px;
                text-align: center;
                animation: slideUp 0.5s cubic-bezier(0.16, 1, 0.3, 1);
            }
            @keyframes slideUp {
                from { opacity: 0; transform: translateY(20px); }
                to { opacity: 1; transform: translateY(0); }
            }
            .login-box h2 {
                margin: 0 0 8px 0;
                color: var(--text-main);
                font-size: 24px;
                font-weight: 700;
            }
            .login-box p {
                color: var(--text-muted);
                margin: 0 0 24px 0;
                font-size: 14px;
            }
            .input-group {
                margin-bottom: 16px;
                text-align: left;
            }
            .login-box input {
                width: 100%;
                padding: 12px 16px;
                border: 1px solid #E5E7EB;
                border-radius: 8px;
                box-sizing: border-box;
                font-family: inherit;
                font-size: 14px;
                transition: all 0.2s;
            }
            .login-box input:focus {
                outline: none;
                border-color: var(--primary);
                box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
            }
            .login-box button {
                width: 100%;
                padding: 12px;
                background-color: var(--primary);
                color: white;
                border: none;
                border-radius: 8px;
                cursor: pointer;
                font-size: 15px;
                font-weight: 600;
                transition: background-color 0.2s, transform 0.1s;
                margin-top: 8px;
            }
            .login-box button:hover {
                background-color: var(--primary-hover);
            }
            .login-box button:active {
                transform: scale(0.98);
            }
            .error {
                color: var(--danger);
                background: #FEF2F2;
                border: 1px solid #FCA5A5;
                padding: 12px;
                border-radius: 8px;
                font-size: 13px;
                margin-bottom: 16px;
                font-weight: 500;
            }
        </style>
    </head>
    <body>
        <div class="login-box">
            <h2>Welcome Back</h2>
            <p>Sign in to access the dashboard</p>
            <?php if (isset($login_error)) echo "<div class='error'>$login_error</div>"; ?>
            <form method="POST" action="">
                <div class="input-group">
                    <input type="text" name="username" placeholder="Username" required autocomplete="off">
                </div>
                <div class="input-group">
                    <input type="password" name="password" placeholder="Password" required>
                </div>
                <button type="submit" name="login">Sign In</button>
            </form>
        </div>
    </body>
    </html>
    <?php
    exit();
}

// Proceed to fetch data if logged in
try {
    $dsn = "mysql:host=" . $db_host . ";dbname=" . $db_name . ";charset=utf8mb4";
    $pdo = new PDO($dsn, $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Fetch all student contacts
    $stmt = $pdo->query("SELECT * FROM student_contacts ORDER BY created_at DESC");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

} catch (PDOException $e) {
    $db_error = "Database connection or table error: " . $e->getMessage();
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FWU - Contact Dashboard</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #4F46E5;
            --surface: #FFFFFF;
            --bg: #F9FAFB;
            --text-main: #111827;
            --text-muted: #6B7280;
            --border: #E5E7EB;
            --danger: #EF4444;
            --danger-hover: #DC2626;
        }

        body {
            font-family: 'Inter', sans-serif;
            background-color: var(--bg);
            margin: 0;
            padding: 40px 20px;
            color: var(--text-main);
        }

        .container {
            max-width: 1100px;
            margin: 0 auto;
            animation: fadeIn 0.4s ease-out;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 30px;
        }

        .header-title h1 {
            margin: 0;
            font-size: 28px;
            font-weight: 700;
            letter-spacing: -0.5px;
            color: var(--text-main);
        }

        .header-title p {
            margin: 5px 0 0 0;
            color: var(--text-muted);
            font-size: 15px;
        }

        .logout-btn {
            padding: 10px 18px;
            background-color: transparent;
            color: var(--danger);
            border: 1px solid var(--border);
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            font-size: 14px;
            transition: all 0.2s;
        }

        .logout-btn:hover {
            background-color: #FEF2F2;
            border-color: #FCA5A5;
        }

        /* Stats Card */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .stat-card {
            background: var(--surface);
            padding: 24px;
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1), 0 1px 2px rgba(0,0,0,0.06);
            border: 1px solid var(--border);
            display: flex;
            flex-direction: column;
        }

        .stat-card span {
            color: var(--text-muted);
            font-size: 14px;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .stat-card strong {
            font-size: 32px;
            font-weight: 700;
            margin-top: 8px;
            color: var(--primary);
        }

        /* Table Card */
        .table-card {
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -1px rgba(0,0,0,0.06);
            border: 1px solid var(--border);
            overflow: hidden;
        }

        .table-responsive {
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
        }

        th {
            background-color: #F8FAFC;
            padding: 16px 20px;
            font-size: 13px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            font-weight: 600;
            color: var(--text-muted);
            border-bottom: 1px solid var(--border);
        }

        td {
            padding: 16px 20px;
            font-size: 14px;
            border-bottom: 1px solid var(--border);
            vertical-align: middle;
        }

        tr:last-child td {
            border-bottom: none;
        }

        tbody tr {
            transition: background-color 0.15s ease;
        }

        tbody tr:hover {
            background-color: #F8FAFC;
        }

        .student-id {
            font-weight: 600;
            color: var(--primary);
        }

        .email-link {
            color: var(--text-main);
            text-decoration: none;
            font-weight: 500;
            transition: color 0.15s;
        }

        .email-link:hover {
            color: var(--primary);
            text-decoration: underline;
        }

        .phone-badge {
            background: #EFF6FF;
            color: #1D4ED8;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 500;
            display: inline-block;
        }

        .date-text {
            color: var(--text-muted);
            font-size: 13px;
        }

        .no-data {
            text-align: center;
            padding: 40px;
            color: var(--text-muted);
        }

        .error-message {
            background-color: #FEF2F2;
            color: var(--danger);
            border: 1px solid #FCA5A5;
            padding: 16px;
            border-radius: 8px;
            margin-bottom: 24px;
            font-weight: 500;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="header-title">
                <h1>Student Contacts</h1>
                <p>Manage synchronized contact information</p>
            </div>
            <a href="?logout=true" class="logout-btn">Sign Out</a>
        </div>

        <?php if (isset($db_error)): ?>
            <div class="error-message">
                <svg style="width:20px;height:20px;vertical-align:-5px;margin-right:5px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                <?php echo htmlspecialchars($db_error); ?>
            </div>
        <?php else: ?>
            
            <div class="stats-grid">
                <div class="stat-card">
                    <span>Total Registered Users</span>
                    <strong><?php echo count($users); ?></strong>
                </div>
            </div>

            <div class="table-card">
                <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th># ID</th>
                                <th>Student ID</th>
                                <th>Email Address</th>
                                <th>Phone Number</th>
                                <th>First Registered</th>
                                <th>Last Sync</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if (count($users) > 0): ?>
                                <?php foreach ($users as $user): ?>
                                    <tr>
                                        <td class="date-text">#<?php echo htmlspecialchars($user['id']); ?></td>
                                        <td class="student-id"><?php echo htmlspecialchars($user['student_id']); ?></td>
                                        <td>
                                            <a class="email-link" href="mailto:<?php echo htmlspecialchars($user['email']); ?>">
                                                <?php echo htmlspecialchars($user['email']); ?>
                                            </a>
                                        </td>
                                        <td>
                                            <span class="phone-badge"><?php echo htmlspecialchars($user['phone'] ?? 'N/A'); ?></span>
                                        </td>
                                        <td class="date-text"><?php echo date('M d, Y', strtotime($user['created_at'])); ?></td>
                                        <td class="date-text"><?php echo date('M d, Y - h:i A', strtotime($user['updated_at'])); ?></td>
                                    </tr>
                                <?php endforeach; ?>
                            <?php else: ?>
                                <tr>
                                    <td colspan="6" class="no-data">
                                        <svg style="width:40px;height:40px;color:#cbd5e1;margin-bottom:10px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path></svg><br>
                                        No users have synced their information yet.
                                    </td>
                                </tr>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>

        <?php endif; ?>
    </div>
</body>
</html>