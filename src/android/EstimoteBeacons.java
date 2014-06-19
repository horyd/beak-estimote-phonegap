package horyd.beakestimotephonegap;

import android.annotation.TargetApi;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.os.Build;
import android.util.Log;
import android.content.Intent;

import java.util.ArrayList;
import java.util.List;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.estimote.sdk.Beacon;
import com.estimote.sdk.BeaconManager;
import com.estimote.sdk.Region;
import com.estimote.sdk.utils.L;

public class EstimoteBeacons extends CordovaPlugin {

	public static final String EXTRAS_TARGET_ACTIVITY = "extrasTargetActivity";
	public static final String EXTRAS_BEACON = "extrasBeacon";
	private static final String TAG = EstimoteBeacons.class.getSimpleName();
	private static final int REQUEST_ENABLE_BT = 1234;
	private static final Region ALL_ESTIMOTE_BEACONS_REGION = new Region("rid", null, null, null);

	private Activity activity;
	private BeaconManager beaconManager;
	private Boolean isBLESupported;
	private Boolean isBLEEnabled;
	private List<Beacon> beacons = null;

	@Override
	public void initialize(CordovaInterface cordova, CordovaWebView webView) {
		super.initialize(cordova, webView);

		Log.d(TAG, "Initializing...");

		activity = cordova.getActivity();

		beaconManager = new BeaconManager(activity);

		// Check if device supports Bluetooth Low Energy.
		isBLESupported = beaconManager.hasBluetooth();
		if (isBLESupported == false) {
			Log.d(TAG, "BLE is NOT supported on this device");
			return;
		}

		Log.d(TAG, "BLE is supported on this device. Waiting for action!");

		// Configure verbose debug logging.
		L.enableDebugLogging(false);
	}

	private Boolean checkBLEEnabled() {
		isBLEEnabled = beaconManager.isBluetoothEnabled();
		if (isBLEEnabled == false) {
			Log.d(TAG, "BLE is NOT enabled on this device");
			// ask permission to the user to enable BLE
			cordova.setActivityResultCallback(this);
			Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
			cordova.startActivityForResult(this, enableBtIntent, REQUEST_ENABLE_BT);
		} else {
			Log.d(TAG, "BLE is enabled on this device");
		}
		return isBLEEnabled;
	}

	@TargetApi(Build.VERSION_CODES.KITKAT)
	private void sendJavascript(final String javascript) {
		webView.post(new Runnable() {
			@Override
			public void run() {
				// See:
				// https://github.com/GoogleChrome/chromium-webview-samples/blob/master/jsinterface-example/src/com/google/chrome/android/example/jsinterface/MainActivity.java
				if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
					webView.evaluateJavascript(javascript, null);
				} else {
					webView.loadUrl("javascript:" + javascript);
				}
			}
		});
	}

	public void onActivityResult(int requestCode, int resultCode, Intent data) {
		if (requestCode == REQUEST_ENABLE_BT) {
			if (resultCode == Activity.RESULT_OK) {
				Log.d(TAG, "BLE is now enabled !");
				// for now, return false for the sync action call.
				// wait for another action
			} else {
				Log.d(TAG, "BLE is not enabled !");
			}
		}
		super.onActivityResult(requestCode, resultCode, data);
	}

	@Override
	public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

		if (this.isBLESupported == false) {
			callbackContext.error("BLE is NOT supported on this device.");
			return false;
		}

		// always check if BLE is activated
		if (this.checkBLEEnabled() == false) {
			Log.e(TAG, "Not ready to take any action.");
			callbackContext.error("Not ready (yet) to take action.");
			return false;
		}

		Log.d(TAG, "Receive action to execute: " + action);

		if (action.equals("startRangingBeaconsInRegion")) {
			this.startRanging(callbackContext);
		}
		else if (action.equals("stopRangingBeaconsInRegion")) {
			this.stopRanging(callbackContext);
		}
		else if (action.equals("getBeacons")) {
			this.getBeacons(callbackContext);
		}
		else {
			callbackContext.error("This action does not exist.");
			return false;
		}

		return true;
	}

	// Cordova callbacks
	private void startRanging(CallbackContext callbackContext) {
		Log.d(TAG, "Start Ranging...");

		final EstimoteBeacons that = this;
		
		// initialize list to an empty list
		this.beacons = new ArrayList<Beacon>();
		
		this.connectToServiceThenStartRanging();

		beaconManager.setRangingListener(new BeaconManager.RangingListener() {
			@Override
			public void onBeaconsDiscovered(Region region, final List<Beacon> beacons) {
				Log.d(TAG, "Found " + beacons.size() + " beacons!");
				that.beacons = beacons;
			}
		});
		callbackContext.success("Start Ranging successful.");
	}

	private void stopRanging(CallbackContext callbackContext) {
		Log.d(TAG, "Stop Ranging...");

		try {
			beaconManager.disconnect();
			
			beaconManager.stopRanging(ALL_ESTIMOTE_BEACONS_REGION);
			// reset list of beacons
			this.beacons = null;
			callbackContext.success("Stop Ranging successful.");
		} catch (Exception e) {
			Log.e(TAG, "Error while stopping ranging", e);
			callbackContext.error("Could not stop ranging.");
		}
	}

	private void getBeacons(CallbackContext callbackContext) {

		if (this.beacons != null) {
			JSONArray beacons = EstimoteBeacons.convertList2JSONArray(this.beacons);
			callbackContext.success(beacons);
		} else {
			callbackContext.error("Could not getBecons.");
		}
	}

	// NON Cordova callbacks (internal methods)
	private void connectToServiceThenStartRanging() {
		Log.d(TAG, "Scanning...");
		
		beaconManager.connect(new BeaconManager.ServiceReadyCallback() {

			@Override
			public void onServiceReady() {
				try {
					beaconManager.startRanging(ALL_ESTIMOTE_BEACONS_REGION);
				} catch (Exception e) {
					Log.e(TAG, "Error while connecting to service", e);
				}
			}
		});
	}

	private static JSONArray convertList2JSONArray(List<Beacon> list) {
		JSONArray jsonArray = new JSONArray();

		for (int i = 0; i < list.size(); i++) {
			Beacon beacon = list.get(i);
			
			JSONObject beaconInfos = new JSONObject();
			try {
				beaconInfos.put("major", beacon.getMajor());
				beaconInfos.put("minor", beacon.getMinor());
				beaconInfos.put("power", beacon.getMeasuredPower());
				beaconInfos.put("rssi", beacon.getRssi());
				beaconInfos.put("macAddress", beacon.getMacAddress());
				beaconInfos.put("name", beacon.getName());
				beaconInfos.put("uuid", beacon.getProximityUUID());
				jsonArray.put(beaconInfos);
			} catch (JSONException e) {
			}
			
		}
		return jsonArray;
	}

}
