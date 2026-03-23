import {
  Button,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { useEffect, useRef, useState } from 'react';
import SplashScreen from '@abeman/react-native-nitro-splash';

export default function App() {
  const showtimer = useRef<NodeJS.Timeout>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Simulate loading app data
    const loadAppData = async () => {
      // Simulate network request or heavy computation
      await new Promise((resolve) => setTimeout(resolve, 2000));
      setIsLoading(false);

      // Hide splash screen with smooth transition
      console.log('Splash screen will hide now');
      SplashScreen.hide();
    };

    loadAppData();

    return () => {
      if (showtimer.current) {
        clearTimeout(showtimer.current);
      }
    };
  }, []);

  const showSplashDefault = () => {
    SplashScreen.show();
    showtimer.current = setTimeout(() => {
      SplashScreen.hide();
    }, 2000);
  };

  const hideSplash = () => {
    if (showtimer.current) {
      clearTimeout(showtimer.current);
    }
    SplashScreen.hide();
  };

  return (
    <ScrollView contentContainerStyle={styles.scrollContainer}>
      <StatusBar barStyle={'dark-content'} />
      <View style={styles.container}>
        <Text style={styles.title}>React Native Splash Screen</Text>
        <Text style={styles.subtitle}>Performance Optimized Demo</Text>

        {isLoading && (
          <Text style={styles.loadingText}>Loading app data...</Text>
        )}

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Basic Controls</Text>
          <Button title="Show Splash " onPress={showSplashDefault} />
          <View style={styles.spacer} />
          <Button title="Hide" onPress={hideSplash} />
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  scrollContainer: {
    flexGrow: 1,
  },
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
    backgroundColor: '#f5f5f5',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 8,
    color: '#333',
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    marginBottom: 24,
  },
  loadingText: {
    fontSize: 14,
    color: '#007AFF',
    marginBottom: 16,
  },
  section: {
    width: '100%',
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 5,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 12,
    color: '#333',
  },
  spacer: {
    height: 12,
  },
  hint: {
    fontSize: 12,
    color: '#999',
    marginTop: 8,
    fontStyle: 'italic',
  },
  feature: {
    fontSize: 14,
    color: '#555',
    marginBottom: 4,
    paddingLeft: 8,
  },
});
