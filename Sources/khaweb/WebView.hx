package khaweb;

#if sys_android

import com.ktxsoftware.kha.KhaActivity;
import android.view.View;
import java.util.concurrent.CountDownLatch;
import java.Lib;

@:forward(loadUrl, loadData)
abstract WebView(WebkitView) {

	inline function new(activity: Activity) {
		var view = new WebkitView(activity);
		view.getSettings().setJavaScriptEnabled(true);
		view.setBackgroundColor(0x00000000);
		var params = new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT);
		activity.addContentView(view, params);
		this = view;
	}

	public static function create(callback: WebView -> Void)
		KhaActivity.the().runOnUiThread(new RunnableTask(function ()
			callback(new WebView(cast KhaActivity.the()))
		));

	public function evaluateJavascript(script: String, callback: String -> Void)
		this.evaluateJavascript(script, new ValueCallbackTask(callback));

}

private class RunnableTask implements java.lang.Runnable {
	var task: Void -> Void;
	public function new(task) this.task = task;
	public function run() task();
}

private class ValueCallbackTask<T> implements ValueCallback<T> {
	var task: T -> Void;
	public function new(task) this.task = task;
	public function onReceiveValue(v) task(v);
}

@:native('android.webkit.WebSettings')
extern class WebSettings {
	function setJavaScriptEnabled(flag: Bool): Void;
}

@:native('android.webkit.WebView')
extern class WebkitView extends View {
	function new(ctx: android.content.Context): Void;
	function getSettings(): WebSettings;
	function loadUrl(url: String): Void;
	function setBackgroundColor(color: Int): Void;
	function loadData(data: String, mimeType: String, encoding: String): Void;
	function evaluateJavascript(script: String, callback: ValueCallback<String>): Void;
}

@:native('android.webkit.ValueCallback')
extern interface ValueCallback<T> {
	function onReceiveValue(value: T): Void;
}

@:native('android.view.ViewGroup.LayoutParams')
extern class LayoutParams {
	static var FILL_PARENT: Int;
	function new(w: Int, h: Int): Void;
}

@:native('android.app.Activity')
private extern class Activity extends android.app.Activity {
	function addContentView(view: View, params: LayoutParams): Void;
}

#end