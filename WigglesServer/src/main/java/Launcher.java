import javax.swing.BorderFactory;
import javax.swing.ButtonGroup;
import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JComboBox;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JRadioButton;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.JTextField;
import javax.swing.SwingUtilities;
import javax.swing.UIManager;
import javax.swing.WindowConstants;
import javax.swing.text.BadLocationException;
import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.awt.Font;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.DirectoryStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Properties;

/**
 * Launcher fuer den Multiplayer: Mitspieler, Port und Rolle eintragen, Starten klicken. Schreibt
 * data/mp_config.tcl, startet den WigglesServer und Wiggles. Ein normaler Spielstart bleibt Einzelspieler.
 */
public class Launcher {

    private static final int MAX_LOG_LINES = 2000;
    private static final String NO_SAVE = "(keiner – Start im Hauptmenü)";

    private final Path gameDir;
    private final Path settingsFile;
    private final MultiplayerSession session;

    private final JFrame frame = new JFrame("Wiggles Multiplayer");
    private final JTextField ownAddresses = new JTextField(20);
    private final JTextField peerAddress = new JTextField(20);
    private final JTextField port = new JTextField(6);
    private final JTextField gamePort = new JTextField(6);
    private final JRadioButton host = new JRadioButton("Host");
    private final JRadioButton client = new JRadioButton("Client");
    private final JComboBox<String> saveGame = new JComboBox<>();
    private final JCheckBox startGame = new JCheckBox("Wiggles automatisch starten");
    private final JButton startButton = new JButton("Starten");
    private final JButton stopButton = new JButton("Stoppen");
    private final JLabel status = new JLabel("Bereit");
    private final JTextArea log = new JTextArea(12, 60);

    public static void main(String[] args) {
        try {
            UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
        } catch (Exception e) {
            // Standard-Look verwenden
        }
        Path gameDir = findGameDir();
        SwingUtilities.invokeLater(() -> new Launcher(gameDir).show());
    }

    /** Der Ordner, in dem die WigglesServer.jar liegt, sonst das Arbeitsverzeichnis. */
    private static Path findGameDir() {
        try {
            Path location = Paths.get(Launcher.class.getProtectionDomain().getCodeSource().getLocation().toURI());
            if (Files.isRegularFile(location)) {
                return location.getParent();
            }
        } catch (URISyntaxException | SecurityException e) {
            // Arbeitsverzeichnis verwenden
        }
        return Paths.get("").toAbsolutePath();
    }

    private Launcher(Path gameDir) {
        this.gameDir = gameDir;
        this.settingsFile = gameDir.resolve("WigglesLauncher.properties");
        this.session = new MultiplayerSession(gameDir, MultiplayerSession.ownServerCommand(), new MultiplayerSession.Listener() {
            public void log(String line) {
                SwingUtilities.invokeLater(() -> appendLog(line));
            }

            public void status(String text) {
                SwingUtilities.invokeLater(() -> status.setText(text));
            }

            public void stopped() {
                SwingUtilities.invokeLater(() -> setRunning(false));
            }
        });
        buildUi();
        loadSettings();
    }

    private void buildUi() {
        ButtonGroup roles = new ButtonGroup();
        roles.add(host);
        roles.add(client);
        ownAddresses.setEditable(false);
        ownAddresses.setText(findOwnAddresses());
        log.setEditable(false);
        log.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 11));
        status.setFont(status.getFont().deriveFont(Font.BOLD));

        JPanel form = new JPanel(new GridBagLayout());
        form.setBorder(BorderFactory.createEmptyBorder(10, 10, 5, 10));
        int row = 0;
        addRow(form, row++, "Eigene IP-Adresse:", ownAddresses, "dem Mitspieler mitteilen");
        addRow(form, row++, "IP-Adresse des Mitspielers:", peerAddress, null);
        addRow(form, row++, "Port:", port, "bei beiden Spielern gleich, in der Firewall freigeben");
        addRow(form, row++, "Spiel-Port:", gamePort, "nur lokal, normalerweise 5593");
        JPanel rolePanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 0, 0));
        rolePanel.add(host);
        rolePanel.add(client);
        addRow(form, row++, "Rolle:", rolePanel, "genau ein Spieler muss Host sein");
        addRow(form, row++, "Spielstand:", saveGame, "nur Host: wird an den Mitspieler geschickt und bei beiden geladen");
        addRow(form, row++, "", startGame, null);

        JPanel buttons = new JPanel(new FlowLayout(FlowLayout.LEFT, 0, 0));
        buttons.add(startButton);
        buttons.add(spacer(8));
        buttons.add(stopButton);
        buttons.add(spacer(16));
        buttons.add(status);
        addRow(form, row, "", buttons, null);

        host.addActionListener(e -> updateSaveGameEnabled());
        client.addActionListener(e -> updateSaveGameEnabled());
        startButton.addActionListener(e -> start());
        stopButton.addActionListener(e -> session.stop());
        setRunning(false);

        JScrollPane logScroll = new JScrollPane(log);
        logScroll.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createEmptyBorder(5, 10, 10, 10), BorderFactory.createTitledBorder("WigglesServer")));

        frame.getContentPane().add(form, BorderLayout.NORTH);
        frame.getContentPane().add(logScroll, BorderLayout.CENTER);
        frame.setDefaultCloseOperation(WindowConstants.DO_NOTHING_ON_CLOSE);
        frame.addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent e) {
                close();
            }
        });
        frame.getRootPane().setDefaultButton(startButton);
        frame.pack();
        frame.setLocationRelativeTo(null);
    }

    private static JLabel spacer(int width) {
        JLabel spacer = new JLabel();
        spacer.setBorder(BorderFactory.createEmptyBorder(0, width, 0, 0));
        return spacer;
    }

    private static void addRow(JPanel panel, int row, String label, java.awt.Component field, String hint) {
        GridBagConstraints c = new GridBagConstraints();
        c.gridy = row;
        c.insets = new Insets(3, 0, 3, 8);
        c.anchor = GridBagConstraints.WEST;
        panel.add(new JLabel(label), c);
        c.gridx = 1;
        c.fill = field instanceof JTextField && ((JTextField) field).getColumns() > 10
                ? GridBagConstraints.HORIZONTAL : GridBagConstraints.NONE;
        c.weightx = 1;
        panel.add(field, c);
        if (hint != null) {
            c.gridx = 2;
            c.fill = GridBagConstraints.NONE;
            c.weightx = 0;
            JLabel hintLabel = new JLabel(hint);
            hintLabel.setEnabled(false);
            panel.add(hintLabel, c);
        }
    }

    private void show() {
        frame.setVisible(true);
    }

    private void setRunning(boolean running) {
        startButton.setEnabled(!running);
        stopButton.setEnabled(running);
        peerAddress.setEnabled(!running);
        port.setEnabled(!running);
        gamePort.setEnabled(!running);
        host.setEnabled(!running);
        client.setEnabled(!running);
        startGame.setEnabled(!running);
        if (!running) {
            refreshSaveGames((String) saveGame.getSelectedItem());
        }
        updateSaveGameEnabled();
    }

    private void start() {
        MultiplayerSession.Settings settings;
        try {
            settings = readSettings();
        } catch (IllegalArgumentException e) {
            JOptionPane.showMessageDialog(frame, e.getMessage(), "Wiggles Multiplayer", JOptionPane.WARNING_MESSAGE);
            return;
        }
        List<String> gameCommand = null;
        if (startGame.isSelected()) {
            File exe = gameDir.resolve("Diggles.exe").toFile();
            if (!exe.isFile()) {
                JOptionPane.showMessageDialog(frame, "Diggles.exe nicht gefunden in " + gameDir
                        + ".\nDer Launcher muss im Wiggles-Ordner liegen.", "Wiggles Multiplayer", JOptionPane.WARNING_MESSAGE);
                return;
            }
            gameCommand = Collections.singletonList(exe.getAbsolutePath());
        }
        saveSettings();
        log.setText("");
        try {
            setRunning(true);
            session.start(settings, gameCommand);
        } catch (IOException e) {
            setRunning(false);
            status.setText("Start fehlgeschlagen");
            JOptionPane.showMessageDialog(frame, "Start fehlgeschlagen: " + e.getMessage(), "Wiggles Multiplayer",
                    JOptionPane.ERROR_MESSAGE);
        }
    }

    private MultiplayerSession.Settings readSettings() {
        MultiplayerSession.Settings settings = new MultiplayerSession.Settings();
        settings.peerAddress = peerAddress.getText().trim();
        if (settings.peerAddress.isEmpty() || settings.peerAddress.contains(" ")) {
            throw new IllegalArgumentException("Bitte die IP-Adresse des Mitspielers eintragen.");
        }
        settings.listenPort = parsePort(port, "Port");
        settings.peerPort = settings.listenPort;
        settings.gamePort = parsePort(gamePort, "Spiel-Port");
        if (settings.gamePort == settings.listenPort) {
            throw new IllegalArgumentException("Port und Spiel-Port mÃ¼ssen verschieden sein.");
        }
        settings.role = host.isSelected() ? MultiplayerSession.ROLE_HOST : MultiplayerSession.ROLE_CLIENT;
        String save = (String) saveGame.getSelectedItem();
        if (host.isSelected() && save != null && !save.equals(NO_SAVE)) {
            settings.saveGame = saveGameDir().resolve(save + ".sav");
            if (!Files.isRegularFile(settings.saveGame)) {
                throw new IllegalArgumentException("Spielstand " + save + " nicht gefunden.");
            }
        }
        return settings;
    }

    private Path saveGameDir() {
        return gameDir.resolve("data").resolve("gamesave");
    }

    /** Liest die Spielstaende neu ein, neueste zuerst, und behaelt die Auswahl bei. */
    private void refreshSaveGames(String selected) {
        List<Path> files = new ArrayList<>();
        try (DirectoryStream<Path> dir = Files.newDirectoryStream(saveGameDir(), "*.sav")) {
            for (Path file : dir) {
                files.add(file);
            }
        } catch (IOException e) {
            // kein Spielstand-Ordner
        }
        files.sort(Comparator.comparing((Path file) -> file.toFile().lastModified()).reversed());
        saveGame.removeAllItems();
        saveGame.addItem(NO_SAVE);
        for (Path file : files) {
            String name = file.getFileName().toString();
            saveGame.addItem(name.substring(0, name.length() - ".sav".length()));
        }
        saveGame.setSelectedItem(selected);
        if (saveGame.getSelectedIndex() < 0) {
            saveGame.setSelectedIndex(0);
        }
    }

    private void updateSaveGameEnabled() {
        saveGame.setEnabled(host.isSelected() && !session.isRunning());
    }

    private static int parsePort(JTextField field, String name) {
        try {
            int value = Integer.parseInt(field.getText().trim());
            if (value > 0 && value < 65536) {
                return value;
            }
        } catch (NumberFormatException e) {
            // unten melden
        }
        throw new IllegalArgumentException(name + " muss eine Zahl zwischen 1 und 65535 sein.");
    }

    private void close() {
        if (session.isRunning()) {
            String message = session.isGameRunning()
                    ? "Wiggles lÃ¤uft noch. Beim SchlieÃen wird die Verbindung zum Mitspieler getrennt.\nTrotzdem schlieÃen?"
                    : "Die Verbindung zum Mitspieler wird getrennt. SchlieÃen?";
            if (JOptionPane.showConfirmDialog(frame, message, "Wiggles Multiplayer", JOptionPane.YES_NO_OPTION)
                    != JOptionPane.YES_OPTION) {
                return;
            }
            session.stop();
        }
        saveSettings();
        frame.dispose();
        System.exit(0);
    }

    private void appendLog(String line) {
        log.append(line + "\n");
        int excess = log.getLineCount() - MAX_LOG_LINES;
        if (excess > 0) {
            try {
                log.replaceRange("", 0, log.getLineEndOffset(excess - 1));
            } catch (BadLocationException e) {
                log.setText("");
            }
        }
        log.setCaretPosition(log.getDocument().getLength());
    }

    private void loadSettings() {
        Properties properties = new Properties();
        if (Files.isRegularFile(settingsFile)) {
            try (InputStream in = Files.newInputStream(settingsFile)) {
                properties.load(in);
            } catch (IOException e) {
                // Standardwerte verwenden
            }
        }
        peerAddress.setText(properties.getProperty("peerAddress", ""));
        port.setText(properties.getProperty("port", "5592"));
        gamePort.setText(properties.getProperty("gamePort", "5593"));
        boolean isClient = MultiplayerSession.ROLE_CLIENT.equals(properties.getProperty("role"));
        host.setSelected(!isClient);
        client.setSelected(isClient);
        startGame.setSelected(!"false".equals(properties.getProperty("startGame")));
        refreshSaveGames(properties.getProperty("saveGame", NO_SAVE));
        updateSaveGameEnabled();
    }

    private void saveSettings() {
        Properties properties = new Properties();
        properties.setProperty("peerAddress", peerAddress.getText().trim());
        properties.setProperty("port", port.getText().trim());
        properties.setProperty("gamePort", gamePort.getText().trim());
        properties.setProperty("role", host.isSelected() ? MultiplayerSession.ROLE_HOST : MultiplayerSession.ROLE_CLIENT);
        properties.setProperty("startGame", String.valueOf(startGame.isSelected()));
        if (saveGame.getSelectedItem() != null) {
            properties.setProperty("saveGame", (String) saveGame.getSelectedItem());
        }
        try (OutputStream out = Files.newOutputStream(settingsFile)) {
            properties.store(out, "Einstellungen des Wiggles Multiplayer Launchers");
        } catch (IOException e) {
            appendLog("Einstellungen nicht gespeichert: " + e.getMessage());
        }
    }

    /** IPv4-Adressen dieses PCs, die der Mitspieler erreichen kann (ohne Loopback). */
    private static String findOwnAddresses() {
        List<String> addresses = new ArrayList<>();
        try {
            for (NetworkInterface networkInterface : Collections.list(NetworkInterface.getNetworkInterfaces())) {
                if (!networkInterface.isUp() || networkInterface.isLoopback()) {
                    continue;
                }
                for (InetAddress address : Collections.list(networkInterface.getInetAddresses())) {
                    if (address instanceof Inet4Address && !address.isLinkLocalAddress()) {
                        addresses.add(address.getHostAddress());
                    }
                }
            }
        } catch (SocketException e) {
            // keine Adressen anzeigen
        }
        return addresses.isEmpty() ? "unbekannt (ipconfig)" : String.join(", ", addresses);
    }
}
