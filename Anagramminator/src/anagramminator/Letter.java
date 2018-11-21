/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package anagramminator;

/**
 * Fully written on my own
 * This class is meant for saving data about every letter in the word, such as which character it is and at which position it has been tried
 * @author yorrick
 */
public class Letter {
    
    public String letter; //this will only save a single character, but it is easier to build a new String from Strings instead of chars
    private final int original_position; //this will save at which position in the original word this letter was found, it is used to check whether two letters are actually the same letter.
    
    Letter(String character, int current_place) {
        letter = character;
        original_position = current_place;
    }
    
    public int getOriginalPosition() { return original_position; } //retrieve the position the letter had in the original word. Used to make sure the same letter is not used twice.
    
}
