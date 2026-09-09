import React from 'react';
import {
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

export default function HomeScreen() {
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <View>
          <Text style={styles.title}>PersonalAssistant</Text>
          <Text style={styles.subtitle}>Your personal AI companion</Text>
        </View>

        <Pressable style={styles.settingsButton}>
          <Text style={styles.settingsText}>⚙️</Text>
        </Pressable>
      </View>

      <View style={styles.welcomeCard}>
        <Text style={styles.welcome}>Hello 👋</Text>
        <Text style={styles.question}>What can I help you with?</Text>

        <View style={styles.inputRow}>
          <TextInput
            placeholder="Ask me anything..."
            placeholderTextColor="#888"
            style={styles.input}
          />

          <Pressable style={styles.micButton}>
            <Text style={styles.micText}>🎙️</Text>
          </Pressable>
        </View>
      </View>

      <Text style={styles.sectionTitle}>Quick Actions</Text>

      <View style={styles.grid}>
        <ActionCard icon="✅" title="Tasks" />
        <ActionCard icon="📝" title="Notes" />
        <ActionCard icon="⏰" title="Reminders" />
        <ActionCard icon="📅" title="Calendar" />
      </View>

      <View style={styles.voiceCard}>
        <Text style={styles.voiceIcon}>🎙️</Text>
        <View>
          <Text style={styles.voiceTitle}>Talk to PersonalAssistant</Text>
          <Text style={styles.voiceSubtitle}>Tap the microphone to speak</Text>
        </View>
      </View>
    </SafeAreaView>
  );
}

function ActionCard({
  icon,
  title,
}: {
  icon: string;
  title: string;
}) {
  return (
    <Pressable style={styles.actionCard}>
      <Text style={styles.actionIcon}>{icon}</Text>
      <Text style={styles.actionTitle}>{title}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: '#f7f7f8',
  },

  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 24,
  },

  title: {
    fontSize: 26,
    fontWeight: '700',
    color: '#111',
  },

  subtitle: {
    marginTop: 4,
    fontSize: 14,
    color: '#777',
  },

  settingsButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },

  settingsText: {
    fontSize: 20,
  },

  welcomeCard: {
    backgroundColor: '#fff',
    borderRadius: 24,
    padding: 20,
    marginBottom: 28,
  },

  welcome: {
    fontSize: 16,
    color: '#777',
    marginBottom: 6,
  },

  question: {
    fontSize: 24,
    fontWeight: '700',
    color: '#111',
    marginBottom: 18,
  },

  inputRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },

  input: {
    flex: 1,
    height: 52,
    backgroundColor: '#f1f1f3',
    borderRadius: 16,
    paddingHorizontal: 16,
    fontSize: 15,
    color: '#111',
  },

  micButton: {
    width: 52,
    height: 52,
    borderRadius: 16,
    marginLeft: 10,
    backgroundColor: '#111',
    alignItems: 'center',
    justifyContent: 'center',
  },

  micText: {
    fontSize: 22,
  },

  sectionTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#111',
    marginBottom: 14,
  },

  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    gap: 12,
  },

  actionCard: {
    width: '48%',
    backgroundColor: '#fff',
    borderRadius: 20,
    padding: 18,
  },

  actionIcon: {
    fontSize: 28,
    marginBottom: 10,
  },

  actionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#111',
  },

  voiceCard: {
    marginTop: 20,
    backgroundColor: '#111',
    borderRadius: 22,
    padding: 20,
    flexDirection: 'row',
    alignItems: 'center',
  },

  voiceIcon: {
    fontSize: 30,
    marginRight: 14,
  },

  voiceTitle: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '700',
  },

  voiceSubtitle: {
    color: '#bbb',
    fontSize: 13,
    marginTop: 4,
  },
});