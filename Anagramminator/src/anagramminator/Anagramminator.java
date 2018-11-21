/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package anagramminator;

import java.io.BufferedReader;
import java.io.FileReader;
import java.net.URL;
import java.util.List;
import java.util.ArrayList;
import java.util.Scanner;
import java.io.BufferedInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;

/**
 * This class/program is completely my own work, except the downloading method.
 * 
 * @author yorrick
 * The Anagramminator is an evil invention which uses a list of all English words from www.mieliestronk.com
 * and two download methods from Pankaj's tutorials (https://www.journaldev.com/924/java-download-file-url).
 * Everything else is written by me, myself, and I
 * 
 * What evil thing does the Anagramminator do, you ask?
 * It takes a word you give and looks for an English anagram of it! Muahahahaha
 */
public class Anagramminator {
    
    static List<String> thesaurus;          //will save all words from mieliestronk.com/corncob_lowercase.txt
    static List<String> possible_anagrams;  //will save all combinations possible with the letters of the inputted word
    static List<Letter> letters;            //will save all letters of the inputted word and their locations in it
    static String input;                    //will save the inputted word
    static boolean found_nothing;           //set to true if none of the combinations are actual words, otherwise set to false
    
    public static void main(String[] args) throws IOException{ //the exception is necessary because downloadWords might throw this exception
        
        thesaurus = downloadWords();                    //put the words in the thesaurus List
        input = retrieveInput();                        //waits for the user to type a word and hit enter (if they type more, it will cut the string at the first non-letter character)
        
        //initialize the Lists as ArrayLists
        possible_anagrams = new ArrayList<String>();
        letters = new ArrayList<Letter>();
        
        String anagram = mixAndMatch();                 //try to create a word with the letters of the inputted word
        
        //Give the user their anagram
        if (found_nothing) {
            System.out.print("The Anagramminator bids you its greatest, sincerest apologies; for there is no anagram for your word.");
        } else {
            System.out.print("The Anagramminator found this anagram for you: " + anagram);
        }
    }
    
    static List<String> downloadWords() throws IOException { //downloads the file with name corncob_lowercase.txt from www.mieliestronk.com/corncob_lowercase.txt
        
        List<String> words = new ArrayList<>(); //will contain all English words
        
        String url = "http://www.mieliestronk.com/corncob_lowercase.txt"; //the URL from which the .txt file will be downloaded
        
        //a downloading method copied from Pankaj's tutorial: https://www.journaldev.com/924/java-download-file-url
        try { //try both downloading methods. If both fail, throw an error.
            downloadUsingNIO(url, "corncob_lowercase.txt");
            downloadUsingStream(url, "corncob_lowercase.txt");
        } catch (IOException e) {
            e.printStackTrace();
        }
        //end of Pankaj's code
        
        //from here on, it's my code again
        
        //read all words from the .txt file and add them to the ArrayList<String> words
        BufferedReader reader = new BufferedReader(new FileReader("corncob_lowercase.txt"));
        String new_word;
        do {            //use do-while so new_word has been assigned when the program reaches the while statement.
                        //Otherwise it would be necessary to use reader.readLine() twice, only saving every even word because it automatically picks the next word
            new_word = reader.readLine();   //save the next word
            words.add(new_word);            //add that word to words
        } while(new_word != null);          //if there is a new word, do this again
        
        words.remove(null);                 //if the null was saved, remove it.
        
        return words;                       //send the words to the thesaurus
    }
    
    static String retrieveInput() { //introduces the user to the Anagramminator and tells them what to do. Also uses a Scanner to read the input.
        //flavor and a warning
        System.out.println("Welcome to the Anagramminator!");
        System.out.println("WARNING! The time the Anagramminator takes grows exponentially with the amount of letters your word has!");
        
        try (
            Scanner scan = new Scanner(System.in)) {    //create a scanner for the input
            System.out.print("Enter your word: ");      //tell the user what they should do
            
            boolean there_is_no_input = true;           //will be set to false as soon as there is input
            do {                                        //wait until there is input (when the user taps enter)
            if(scan.hasNext()) there_is_no_input = false;
            } while (there_is_no_input);
            
            String text = scan.next();                  //read the input and save it in a String
            
            scan.close();                               //close the Scanner so it won't slow down the program
            
            System.out.println("The Anagramminator will now look for English anagrams to the word: " + text); //feedback to the user what the program will do
            return text;                                //return the inputted word
        }
    }
    
    static String mixAndMatch() {   //splits the inputted word into Letters, calls the createAnagrams() function,
                                    //and checks whether any of the combinations found is an anagram
        
        String anagram = new String();                              //will save the found anagram, or if none: "no anagram"
        
        for (int i = 0; i<input.length(); i++) {                    //split the inputted string into Strings of one character long,
                                                                    //then save them and their location as a Letter
            String next_letter = input.substring(i, i+1);
            letters.add(new Letter(next_letter, i));
        }
        
        createAnagrams();                                           //make every possible combination with the given letters
        
        for (String s : possible_anagrams) {                        //for every combination
            if (isAnagram(s) && (s.length() == input.length()) ) {  //check whether the length is correct and it is an anagram
                anagram = s;                                        //if so, the program found something and should return the anagram
                found_nothing = false;                              //(it will return the first anagram it finds, since it will stop looking after that)
                break;
            } else {                                                //if not, the program found nothing and should return there is no anagram
                found_nothing = true;
                anagram = "no anagram";
            }
        }
        
        return anagram;                                             //return the found anagram to the main function
    }
    
    
    static void createAnagrams() {                      //prepares to use the recursive addLetter function
        String possible_anagram = new String();         //an empty String which the addLetter function uses so it can start
        
        ArrayList<Letter> placed_letters;               //an empty ArrayList<Letter> which the addLetter function uses so it can start
        placed_letters = new ArrayList<>();
        
        addLetter(possible_anagram, placed_letters);    //the addLetter function will use recursion and a for-each-loop to build every possible combination of Letters step by step
    }
    
    static void addLetter(String possible_anagram, ArrayList<Letter> placed_letters) {  //a recursive function which adds one character to the possible anagram every time,
                                                                                        //saving which Letters have already been used so they won't be used twice.
        
        ArrayList<Letter> additional_letters = placed_letters;  //saves the Letters which have already been used in this branch of the possibility tree (placed_letters)
                                                                //and will add the one used in this possibility
        
        for (Letter l : letters) {                              //for each Letter l in the inputted word
            String new_anagram = possible_anagram;              //make a new String, which copies the received String and will receive one more character
            
            if (additional_letters.size() == letters.size()) {  //if the amount of Letters used is equal to the amount of letters the original word had
                possible_anagrams.add(new_anagram);             //this possible anagram is the correct length and contains all letters. It should be saved to the list of combinations
                break;                                          //then break this loop to prevent unneccesary lag
            } else if (!placed_letters.contains(l)) {           //otherwise, if l has not been used yet
                new_anagram += l.letter;                        //add l's letter to the new anagram
                additional_letters.add(l);                      //add l to the list of used Letters
                addLetter(new_anagram, additional_letters);     //call this function again to start a new branch of possibilities from here
                additional_letters.remove(l);                   //after having tested all possibilities from here, remove l from the used letters
                                                                //so a different letter can be placed in its place and l can be used at a different position in the next combination
            }
             
        }
    }
    
    static boolean isAnagram(String possible_anagram) { //returns whether the received String is a word, other than the inputted word
        boolean this_is_an_anagram = false;     //will be set to true if possible_anagram is an actual_anagram
        
        for (String s : thesaurus) {            //look through all the words in thesaurus if the possible_anagram is actually a word and checks if it is not the inputted word
            if (possible_anagram.equals(s) && !possible_anagram.equals(input)) {
                this_is_an_anagram = true;      //if it is a word and not the input, return true
                break;                          //then stop looking to prevent lag.
            }
        }
        
        return this_is_an_anagram;              //return whether the received String is an anagram or not
    }
    
    //Two download methods copied from Pankaj's tutorial: https://www.journaldev.com/924/java-download-file-url
    //I am not exactly sure how they do it but, hey, they work
    
    private static void downloadUsingStream(String urlStr, String file) throws IOException{
        URL url = new URL(urlStr);
        BufferedInputStream bis = new BufferedInputStream(url.openStream());
        FileOutputStream fis = new FileOutputStream(file);
        byte[] buffer = new byte[1024];
        int count=0;
        while((count = bis.read(buffer,0,1024)) != -1)
        {
            fis.write(buffer, 0, count);
        }
        fis.close();
        bis.close();
    }

    private static void downloadUsingNIO(String urlStr, String file) throws IOException {
        URL url = new URL(urlStr);
        ReadableByteChannel rbc = Channels.newChannel(url.openStream());
        FileOutputStream fos = new FileOutputStream(file);
        fos.getChannel().transferFrom(rbc, 0, Long.MAX_VALUE);
        fos.close();
        rbc.close();
    }
    
}
