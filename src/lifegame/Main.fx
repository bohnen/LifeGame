/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package lifegame;

import javafx.stage.Stage;
import javafx.scene.Scene;
import javafx.scene.paint.Color;
import javafx.scene.shape.Circle;
import javafx.animation.Timeline;
import javafx.animation.KeyFrame;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.VBox;
import javafx.scene.layout.HBox;
import javafx.scene.control.Button;
import javafx.scene.Group;
import javafx.scene.control.Label;
import javafx.geometry.HPos;
import javafx.scene.text.Font;

/**
 * @author bohnen
 */
def MATRIX_SIZE = 50;

class Row {

	public-read var columns: Boolean[] = for (i in [0..<MATRIX_SIZE]) false;
}

class Update {

	public var x: Integer;
	public var y: Integer;
	public var v: Boolean;
}

class Matrix {

	public-read var rows: Row[] = bind for (i in [0..<MATRIX_SIZE]) Row {};
	public-read var generation = 0;
	public-read var stack = false;
	// next state. Changes are recorded.
	var updates: Update[] = [];


	function get(x: Integer, y: Integer): Boolean {
		return rows[x].columns[y];
	}

	function birth(x: Integer, y: Integer): Matrix {
		insert Update { x: x, y: y, v: true } into updates;
		//rows[x].columns[y] = true;
		return this;
	}

	function death(x: Integer, y: Integer): Matrix {
		insert Update { x: x, y: y, v: false } into updates;
		//rows[x].columns[y] = false;
		return this;
	}

	function turn(x: Integer, y: Integer): Matrix {
		rows[x].columns[y] = not rows[x].columns[y];
		return this;
	}

	function check(x: Integer, y: Integer): Void {
		var count = 0;
		for (i in [-1..1]) {
			if (x + i < 0 or x + i >= MATRIX_SIZE) continue;
			for (j in [-1..1]) {
				if (y + i < 0 or y + i >= MATRIX_SIZE) continue;
				if (i == 0 and j == 0) continue;
				if (get(x + i, y + j)) count++;
			}
		}
		if (get(x, y)) {
			if (count != 2 and count != 3) {
				death(x, y);
			//println("({x},{y})={count}");
			}
		} else {
			if (count == 3) birth(x, y)
		}
	}

	// Calculate next state from current state.
	function gen(): Void {
		for (i in [0..<MATRIX_SIZE]) {
			for (j in [0..<MATRIX_SIZE]) {
				check(i, j);
			}
		}
		next();
	}

	// Go to next state.
	function next(): Void {
		if (updates.size() == 0) {
			stack = true;
		} else {
			for (u in updates) {
				rows[u.x].columns[u.y] = u.v;
				//println("({u.x},{u.y})={u.v}");
			}
			stack = false;
			updates = [];
			generation++;
		}
	}

}
var rd = 5; // initial radius
def matrix = Matrix {}
def circles = Group {
			translateX: 5
			translateY: 5
			content: for (i in [0..<MATRIX_SIZE]) {
				for (j in [0..<MATRIX_SIZE]) {
					Circle {
						translateX: (i + 1) * 10
						translateY: (j + 1) * 10
						radius: bind if (matrix.rows[i].columns[j]) rd else 5
						fill: bind if (matrix.rows[i].columns[j]) Color.RED else Color.WHITE

						onMouseClicked: function(e: MouseEvent): Void {
							matrix.turn(i, j);
						}
					}
				}
			}
		}

def clock: Timeline = Timeline {
			repeatCount: Timeline.INDEFINITE
			keyFrames: [
				KeyFrame {
					time: 1s
					action: function() {
						matrix.gen();
						if(matrix.stack) running = false;
					}
				}
			]
		};

/**
 * Heatbeat Animation
 */
def heatbeat: Timeline = Timeline {
	repeatCount: Timeline.INDEFINITE
	rate: 0.25
	keyFrames: [
		at (0.0s) {rd => 5},
		at (0.25s) {rd => 2},
		at (0.5s) {rd => 4},
		at (0.75s) {rd => 2}
		at (1.0s) {rd => 5},
	]
};

var running = false on replace {
	if(running){
		clock.play();
		heatbeat.play();
	}else{
		clock.pause();
		heatbeat.stop();
	}
};

// GUI Elements
def stopButton = Button {
			text: "STOP"
			onMouseClicked: function(e: MouseEvent): Void {
				//clock.pause();
				running = false;

			}
		};
def startButton = Button {
			text: "START"
			onMouseClicked: function(e: MouseEvent): Void {
				//clock.play();
				running = true;

			}
		};
def generation = Label {
			text: bind "Generation:{matrix.generation}"
			font: Font {
				name: "Tahoma"
				size: 16
			}
			textFill: Color.RED
		};

matrix.birth(10, 10).birth(10, 9).birth(10, 11).birth(12, 10).next();

Stage {
	title: "Life Game"
	resizable: false
	scene: Scene {
		width: (MATRIX_SIZE + 1) * 10
		height: (MATRIX_SIZE + 1) * 10 + 30
		fill: Color.LIGHTGREEN;
		//content: circles
		content: VBox {
			spacing: 10
			nodeHPos: HPos.CENTER
			content: [
				circles,
				HBox {
					hpos: HPos.CENTER
					spacing: 5
					content: [startButton, stopButton, generation]
				}
			]
		}
	}
}
