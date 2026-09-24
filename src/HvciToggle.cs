// HVCI Toggle
// A tiny Windows utility to turn Memory Integrity (HVCI) on or off.
//
// What it changes:
//   1. HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\
//        HypervisorEnforcedCodeIntegrity  ->  Enabled (DWORD) = 0 / 1
//   2. bcdedit /set hypervisorlaunchtype off / auto
//
// A restart is required for changes to take effect.

using System;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using Microsoft.Win32;

namespace HvciToggle
{
    internal static class Program
    {
        [STAThread]
        private static void Main()
        {
            Application.EnableVisualStyles();
            Application.Run(new MainForm());
        }
    }

    /// <summary>Reads and writes the HVCI and hypervisor settings.</summary>
    internal static class HvciSettings
    {
        private const string HvciKeyPath =
            @"SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity";
        private const string EnabledValueName = "Enabled";

        public static bool IsHvciEnabled()
        {
            using (RegistryKey key = Registry.LocalMachine.OpenSubKey(HvciKeyPath))
            {
                object value = key == null ? null : key.GetValue(EnabledValueName);
                return value is int && (int)value == 1;
            }
        }

        /// <summary>Returns the current hypervisorlaunchtype ("auto" when not set).</summary>
        public static string GetHypervisorLaunchType()
        {
            string output = ProcessRunner.Run("bcdedit", "/enum {current}");

            foreach (string rawLine in output.Split('\n'))
            {
                string line = rawLine.Trim();
                if (!line.StartsWith("hypervisorlaunchtype", StringComparison.OrdinalIgnoreCase))
                    continue;

                string[] parts = line.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length > 1)
                    return parts[1].ToLowerInvariant();
            }

            return "auto";
        }

        public static void SetEnabled(bool enable)
        {
            using (RegistryKey key = Registry.LocalMachine.CreateSubKey(HvciKeyPath))
            {
                key.SetValue(EnabledValueName, enable ? 1 : 0, RegistryValueKind.DWord);
            }

            ProcessRunner.Run("bcdedit", "/set hypervisorlaunchtype " + (enable ? "auto" : "off"));
        }
    }

    internal static class ProcessRunner
    {
        /// <summary>Runs a command hidden and returns its standard output.</summary>
        public static string Run(string fileName, string arguments)
        {
            var startInfo = new ProcessStartInfo(fileName, arguments)
            {
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true
            };

            using (Process process = Process.Start(startInfo))
            {
                string output = process.StandardOutput.ReadToEnd();
                process.WaitForExit();
                return output;
            }
        }
    }

    internal sealed class MainForm : Form
    {
        // Palette
        private static readonly Color BackgroundColor = Color.FromArgb(255, 244, 248);
        private static readonly Color PinkColor = Color.FromArgb(255, 143, 177);
        private static readonly Color MintColor = Color.FromArgb(120, 214, 170);
        private static readonly Color LilacColor = Color.FromArgb(178, 150, 240);
        private static readonly Color InkColor = Color.FromArgb(90, 70, 100);

        // Layout
        private const int FormWidth = 360;
        private const int FormHeight = 400;
        private const int ButtonWidth = 260;
        private const int ButtonHeight = 48;
        private const int ButtonCornerRadius = 22;

        private const string FaceOn = "(｡•̀ᴗ-)✧";
        private const string FaceOff = "(｡-ω-)zzz";

        private readonly Label faceLabel;
        private readonly Label statusLabel;

        public MainForm()
        {
            Text = "HVCI Toggle";
            ClientSize = new Size(FormWidth, FormHeight);
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox = false;
            StartPosition = FormStartPosition.CenterScreen;
            BackColor = BackgroundColor;
            Font = new Font("Segoe UI", 10f);
            Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);

            faceLabel = new Label
            {
                Font = new Font("Segoe UI", 30f),
                ForeColor = PinkColor,
                TextAlign = ContentAlignment.MiddleCenter,
                Bounds = new Rectangle(0, 18, FormWidth, 60)
            };

            var titleLabel = new Label
            {
                Text = "hvci toggle",
                Font = new Font("Segoe UI Semibold", 16f),
                ForeColor = InkColor,
                TextAlign = ContentAlignment.MiddleCenter,
                Bounds = new Rectangle(0, 80, FormWidth, 34)
            };

            statusLabel = new Label
            {
                ForeColor = InkColor,
                TextAlign = ContentAlignment.MiddleCenter,
                Bounds = new Rectangle(20, 116, 320, 50)
            };

            Button offButton = CreateRoundedButton("turn it OFF  (-_-) zzz", PinkColor, 180);
            Button onButton = CreateRoundedButton("turn it ON  (•̀ᴗ•́)و", MintColor, 240);
            Button restartButton = CreateRoundedButton("restart now  ↻", LilacColor, 310);

            offButton.Click += (sender, e) => ApplySetting(false);
            onButton.Click += (sender, e) => ApplySetting(true);
            restartButton.Click += (sender, e) => ConfirmAndRestart();

            Controls.AddRange(new Control[] { faceLabel, titleLabel, statusLabel, offButton, onButton, restartButton });

            RefreshStatus();
        }

        private void ApplySetting(bool enable)
        {
            try
            {
                HvciSettings.SetEnabled(enable);
                RefreshStatus();
                statusLabel.Text += "\nrestart to apply ♡";
            }
            catch (Exception ex)
            {
                MessageBox.Show("Oops: " + ex.Message, "HVCI Toggle", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void RefreshStatus()
        {
            bool hvciEnabled = HvciSettings.IsHvciEnabled();
            string hypervisor = HvciSettings.GetHypervisorLaunchType();

            faceLabel.Text = hvciEnabled ? FaceOn : FaceOff;
            statusLabel.Text = "HVCI: " + (hvciEnabled ? "ON" : "OFF") + "   ·   Hypervisor: " + hypervisor;
        }

        private static void ConfirmAndRestart()
        {
            DialogResult answer = MessageBox.Show(
                "Restart right now? Save your stuff first!",
                "Restart",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question);

            if (answer == DialogResult.Yes)
                ProcessRunner.Run("shutdown", "/r /f /t 0");
        }

        private static Button CreateRoundedButton(string text, Color color, int top)
        {
            var button = new Button
            {
                Text = text,
                Bounds = new Rectangle((FormWidth - ButtonWidth) / 2, top, ButtonWidth, ButtonHeight),
                FlatStyle = FlatStyle.Flat,
                BackColor = color,
                ForeColor = Color.White,
                Font = new Font("Segoe UI Semibold", 11f),
                Cursor = Cursors.Hand
            };
            button.FlatAppearance.BorderSize = 0;
            button.FlatAppearance.MouseOverBackColor = ControlPaint.Light(color, 0.3f);

            using (GraphicsPath path = CreateRoundedRectangle(button.Width, button.Height, ButtonCornerRadius))
            {
                button.Region = new Region(path);
            }

            return button;
        }

        private static GraphicsPath CreateRoundedRectangle(int width, int height, int diameter)
        {
            var path = new GraphicsPath();
            path.AddArc(0, 0, diameter, diameter, 180, 90);
            path.AddArc(width - diameter, 0, diameter, diameter, 270, 90);
            path.AddArc(width - diameter, height - diameter, diameter, diameter, 0, 90);
            path.AddArc(0, height - diameter, diameter, diameter, 90, 90);
            path.CloseFigure();
            return path;
        }
    }
}
